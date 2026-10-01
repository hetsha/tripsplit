<?php
/**
 * TripBook Trips API
 */

declare(strict_types=1);

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/functions.php';
require_once __DIR__ . '/../includes/auth.php';
require_once __DIR__ . '/../includes/validation.php';
require_once __DIR__ . '/../includes/calculations.php';

header('Content-Type: application/json; charset=utf-8');

$currentUser = getCurrentUser();
$db = getDBConnection();
$method = $_SERVER['REQUEST_METHOD'];
$action = $_GET['action'] ?? $_POST['action'] ?? 'get';

if ($method === 'GET') {
    // 1. List all trips for the current user
    if ($action === 'list') {
        $userId = (int)$currentUser['id'];

        $stmt = $db->prepare("
            SELECT t.id, t.trip_code, t.url_token, t.name, t.description, t.starting_money, t.currency_symbol, t.created_at, tm.role
            FROM trips t
            JOIN trip_members tm ON tm.trip_id = t.id
            WHERE tm.user_id = ?
            ORDER BY t.created_at DESC
        ");
        $stmt->execute([$userId]);
        $rawTrips = $stmt->fetchAll();

        // If user has no joined trips, fetch all public/active trips
        if (empty($rawTrips)) {
            $stmt = $db->query("
                SELECT t.id, t.trip_code, t.url_token, t.name, t.description, t.starting_money, t.currency_symbol, t.created_at, 'member' as role
                FROM trips t
                ORDER BY t.created_at DESC
            ");
            $rawTrips = $stmt->fetchAll();
        }

        $tripsList = [];
        $totalSpentAll = 0.0;
        $activeSpentAll = 0.0;
        $totalToReceiveAll = 0.0;
        $totalToPayAll = 0.0;
        $connectedFriends = [];
        $activeTripsCount = 0;
        $settledTripsCount = 0;

        foreach ($rawTrips as $t) {
            $tripId = (int)$t['id'];

            // Fetch members
            $memStmt = $db->prepare("
                SELECT u.id, u.name, u.avatar_color 
                FROM trip_members tm 
                JOIN users u ON u.id = tm.user_id 
                WHERE tm.trip_id = ?
            ");
            $memStmt->execute([$tripId]);
            $tripMembers = $memStmt->fetchAll();
            $membersCount = count($tripMembers);
            foreach ($tripMembers as $tm) {
                if ((int)$tm['id'] !== $userId) {
                    $connectedFriends[(int)$tm['id']] = true;
                }
            }

            // Total spent
            $expStmt = $db->prepare("SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE trip_id = ? AND type = 'expense'");
            $expStmt->execute([$tripId]);
            $totalSpent = (float)$expStmt->fetch()['total'];
            $totalSpentAll += $totalSpent;

            // Splitwise balances & user position
            $balances = getSplitwiseBalances($tripId);
            $myNet = isset($balances[$userId]) ? (float)$balances[$userId]['net_balance'] : 0.0;

            $isSettled = true;
            foreach ($balances as $b) {
                if (abs((float)$b['net_balance']) > 0.01) {
                    $isSettled = false;
                    break;
                }
            }

            if ($isSettled && $totalSpent > 0) {
                $settledTripsCount++;
            } else {
                $activeTripsCount++;
                // Only active (unsettled) trips contribute to active vault spending and active balances:
                $activeSpentAll += $totalSpent;
                if ($myNet > 0.01) {
                    $totalToReceiveAll += $myNet;
                } elseif ($myNet < -0.01) {
                    $totalToPayAll += abs($myNet);
                }
            }

            $tripsList[] = [
                'id'              => $tripId,
                'trip_code'       => $t['trip_code'],
                'url_token'       => $t['url_token'],
                'title'           => $t['name'],
                'destination'     => $t['description'] ?: $t['name'],
                'starting_money'  => (float)$t['starting_money'],
                'total_budget'    => (float)$t['starting_money'] > 0 ? (float)$t['starting_money'] : max($totalSpent * 1.25, 5000),
                'total_spent'     => $totalSpent,
                'currency_symbol' => $t['currency_symbol'] ?: '₹',
                'members_count'   => $membersCount,
                'members'         => $tripMembers,
                'role'            => $t['role'],
                'my_net_balance'  => $myNet,
                'is_positive'     => $myNet >= 0,
                'is_settled'      => $isSettled,
                'created_at'      => $t['created_at'],
            ];
        }

        jsonSuccess('Trips list loaded', [
            'trips' => $tripsList,
            'stats' => [
                'total_trips'      => count($tripsList),
                'active_trips'     => $activeTripsCount,
                'settled_trips'    => $settledTripsCount,
                'total_spent'      => $activeSpentAll,
                'all_time_spent'   => $totalSpentAll,
                'total_to_receive' => $totalToReceiveAll,
                'total_to_pay'     => $totalToPayAll,
                'friends_count'    => count($connectedFriends),
            ],
            'user'  => $currentUser
        ]);
    }

    // 2. Single trip details
    $tripId = (int)($_GET['trip_id'] ?? getActiveTripId());
    $membership = requireTripMembership($tripId, (int)$currentUser['id']);

    $stmt = $db->prepare("
        SELECT t.*, u.name as creator_name, sp.name as starting_payer_name
        FROM trips t
        JOIN users u ON u.id = t.created_by
        LEFT JOIN users sp ON sp.id = t.starting_payer_id
        WHERE t.id = ?
    ");
    $stmt->execute([$tripId]);
    $trip = $stmt->fetch();

    // Get members
    $stmt = $db->prepare("
        SELECT u.id, u.name, u.email, u.phone, u.avatar_color, tm.role, tm.joined_at
        FROM trip_members tm
        JOIN users u ON u.id = tm.user_id
        WHERE tm.trip_id = ?
        ORDER BY tm.joined_at ASC
    ");
    $stmt->execute([$tripId]);
    $members = $stmt->fetchAll();

    jsonSuccess('Trip details', [
        'trip'       => $trip,
        'role'       => $membership['role'],
        'members'    => $members,
        'is_creator' => ((int)$trip['created_by'] === (int)$currentUser['id'])
    ]);
}

if ($method === 'POST') {
    requireCsrf();
    $input = getJsonInput();
    $act = $input['action'] ?? $action;

    // Resolve url_token to trip_id
    if ($act === 'resolve_token') {
        $token = trim((string)($input['url_token'] ?? ''));
        if (empty($token)) {
            jsonError('Token is required', 422);
        }
        $stmt = $db->prepare("SELECT id FROM trips WHERE url_token = ?");
        $stmt->execute([$token]);
        $row = $stmt->fetch();
        if (!$row) {
            jsonError('Invalid trip link', 404);
        }
        $resolvedTripId = (int)$row['id'];
        requireTripMembership($resolvedTripId, (int)$currentUser['id']);
        setActiveTripId($resolvedTripId);
        jsonSuccess('Trip resolved', ['trip_id' => $resolvedTripId]);
    }

    // Create Trip
    if ($act === 'create') {
        $name = trim((string)($input['name'] ?? ''));
        $description = trim((string)($input['description'] ?? ''));
        $startingMoney = max(0.0, round((float)($input['starting_money'] ?? 0), 2));
        $startingMethod = validatePaymentMethod($input['starting_payment_method'] ?? 'cash');
        $currencySymbol = trim((string)($input['currency_symbol'] ?? '₹')) ?: '₹';
        $memberNames = $input['members'] ?? [];

        if (empty($name)) {
            jsonError('Trip name is required', 422);
        }

        // Dedupe: ignore double-tap / retry creating same trip within 15 sec
        $dupStmt = $db->prepare("SELECT id, trip_code, url_token FROM trips WHERE created_by = ? AND name = ? AND created_at >= (NOW() - INTERVAL 15 SECOND) ORDER BY id DESC LIMIT 1");
        $dupStmt->execute([$currentUser['id'], $name]);
        $dup = $dupStmt->fetch();
        if ($dup) {
            setActiveTripId((int)$dup['id']);
            jsonSuccess('Trip created successfully!', [
                'trip_id'   => (int)$dup['id'],
                'trip_code' => $dup['trip_code'],
                'url_token' => $dup['url_token'],
                'duplicate' => true
            ]);
        }

        $tripCode = generateTripCode();
        $urlToken = strtolower(substr(md5(uniqid((string)random_int(100000, 99999999), true)), 0, 8));

        $db->beginTransaction();
        try {
            $stmt = $db->prepare("
                INSERT INTO trips (trip_code, url_token, name, description, starting_money, starting_payer_id, starting_payment_method, currency_symbol, created_by)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([
                $tripCode,
                $urlToken,
                $name,
                $description ?: null,
                $startingMoney,
                $currentUser['id'],
                $startingMethod,
                $currencySymbol,
                $currentUser['id']
            ]);
            $newTripId = (int)$db->lastInsertId();

            // Add creator as owner
            $stmt = $db->prepare("INSERT INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'owner')");
            $stmt->execute([$newTripId, $currentUser['id']]);

            // Add additional member names if provided
            if (is_array($memberNames)) {
                foreach ($memberNames as $mName) {
                    $mName = trim((string)$mName);
                    if (!empty($mName) && strcasecmp($mName, $currentUser['name']) !== 0) {
                        // Check if user exists or create new
                        $uStmt = $db->prepare("SELECT id FROM users WHERE LOWER(name) = LOWER(?) LIMIT 1");
                        $uStmt->execute([$mName]);
                        $existingUser = $uStmt->fetch();

                        if ($existingUser) {
                            $memberUserId = (int)$existingUser['id'];
                        } else {
                            $colors = ['#2563eb', '#10b981', '#f59e0b', '#8b5cf6', '#ec4899', '#06b6d4', '#f97316'];
                            $avatarColor = $colors[array_rand($colors)];
                            $insStmt = $db->prepare("INSERT INTO users (name, password_hash, avatar_color) VALUES (?, ?, ?)");
                            $insStmt->execute([$mName, password_hash(bin2hex(random_bytes(16)), PASSWORD_DEFAULT), $avatarColor]);
                            $memberUserId = (int)$db->lastInsertId();
                        }

                        $memStmt = $db->prepare("INSERT IGNORE INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'member')");
                        $memStmt->execute([$newTripId, $memberUserId]);
                    }
                }
            }

            $db->commit();
            setActiveTripId($newTripId);

            jsonSuccess('Trip created successfully!', [
                'trip_id'   => $newTripId,
                'trip_code' => $tripCode,
                'url_token' => $urlToken
            ]);
        } catch (Throwable $e) {
            $db->rollBack();
            jsonError('Failed to create trip: ' . $e->getMessage(), 500);
        }
    }

    // Join Trip by Code
    if ($act === 'join') {
        $tripCode = strtoupper(trim((string)($input['trip_code'] ?? '')));
        if (empty($tripCode)) {
            jsonError('Trip code is required', 422);
        }

        $stmt = $db->prepare("SELECT id, name, url_token FROM trips WHERE trip_code = ?");
        $stmt->execute([$tripCode]);
        $trip = $stmt->fetch();

        if (!$trip) {
            jsonError('Invalid trip code. Please check and try again.', 404);
        }

        $tripId = (int)$trip['id'];

        $stmt = $db->prepare("INSERT IGNORE INTO trip_members (trip_id, user_id, role) VALUES (?, ?, 'member')");
        $stmt->execute([$tripId, $currentUser['id']]);

        $joinerName = $currentUser['name'];
        createNotification($tripId, 'member_joined', "$joinerName joined the trip");

        setActiveTripId($tripId);
        jsonSuccess("Joined {$trip['name']} successfully!", ['trip_id' => $tripId, 'url_token' => $trip['url_token']]);
    }

    // Update Trip Settings
    if ($act === 'update') {
        $tripId = (int)($input['trip_id'] ?? getActiveTripId());
        requireTripMembership($tripId, (int)$currentUser['id']);

        $name = trim((string)($input['name'] ?? ''));
        $description = trim((string)($input['description'] ?? ''));
        $startingMoney = validateAmount($input['starting_money'] ?? 0.0, 'Starting Money');
        $startingMethod = validatePaymentMethod($input['starting_payment_method'] ?? 'cash');

        if (empty($name)) {
            jsonError('Trip name cannot be empty', 422);
        }

        $stmt = $db->prepare("
            UPDATE trips 
            SET name = ?, description = ?, starting_money = ?, starting_payment_method = ?
            WHERE id = ?
        ");
        $stmt->execute([$name, $description ?: null, $startingMoney, $startingMethod, $tripId]);

        jsonSuccess('Trip settings updated successfully');
    }

    // Delete Trip
    if ($act === 'delete') {
        $tripId = (int)($input['trip_id'] ?? getActiveTripId());
        $membership = requireTripMembership($tripId, (int)$currentUser['id']);

        if ($membership['role'] !== 'owner') {
            jsonError('Only the trip owner can delete the trip', 403);
        }

        $stmt = $db->prepare("DELETE FROM trips WHERE id = ?");
        $stmt->execute([$tripId]);

        // Find next trip
        $stmt = $db->prepare("SELECT trip_id FROM trip_members WHERE user_id = ? LIMIT 1");
        $stmt->execute([$currentUser['id']]);
        $nextTrip = $stmt->fetch();
        $nextId = $nextTrip ? (int)$nextTrip['trip_id'] : 0;
        setActiveTripId($nextId);

        jsonSuccess('Trip deleted successfully', ['active_trip_id' => $nextId]);
    }

    jsonError('Invalid action', 400);
}
