clear
close all
clc

sim = remApi('remoteApi');
sim.simxFinish(-1);
clientID = sim.simxStart('127.0.0.1', 19999, true, true, 5000, 5);

if clientID > -1
    disp('Connected to CoppeliaSim');

    handles = zeros(1, 11);


    [~, handles(1)] = sim.simxGetObjectHandle(clientID, 'rollingJoint_rr', sim.simx_opmode_blocking);
    [~, handles(2)] = sim.simxGetObjectHandle(clientID, 'rollingJoint_rl', sim.simx_opmode_blocking);
    [~, handles(3)] = sim.simxGetObjectHandle(clientID, 'rollingJoint_fr', sim.simx_opmode_blocking);
    [~, handles(4)] = sim.simxGetObjectHandle(clientID, 'rollingJoint_fl', sim.simx_opmode_blocking);


    [~, handles(5)]  = sim.simxGetObjectHandle(clientID, 'youBotArmJoint0', sim.simx_opmode_blocking);
    [~, handles(6)]  = sim.simxGetObjectHandle(clientID, 'youBotArmJoint1', sim.simx_opmode_blocking);
    [~, handles(7)]  = sim.simxGetObjectHandle(clientID, 'youBotArmJoint2', sim.simx_opmode_blocking);
    [~, handles(8)]  = sim.simxGetObjectHandle(clientID, 'youBotArmJoint3', sim.simx_opmode_blocking);
    [~, handles(9)]  = sim.simxGetObjectHandle(clientID, 'youBotArmJoint4', sim.simx_opmode_blocking);

 
    handles(10) = -1;
    handles(11) = -1;

    gripperJ1Candidates = { ...
        'youBotGripperJoint1', ...
        'youBotGripper.Joint1', ...
        'youBot_gripperJoint1', ...
        'gripper_joint_1', ...
        'youBotLeftGripperFinger', ...
        'youBotGripperFingerJoint_1' };

    gripperJ2Candidates = { ...
        'youBotGripperJoint2', ...
        'youBotGripper.Joint2', ...
        'youBot_gripperJoint2', ...
        'gripper_joint_2', ...
        'youBotRightGripperFinger', ...
        'youBotGripperFingerJoint_2' };

    foundJ1Name = '';
    foundJ2Name = '';

    for k = 1:length(gripperJ1Candidates)
        [rc, h] = sim.simxGetObjectHandle(clientID, gripperJ1Candidates{k}, sim.simx_opmode_blocking);
        if rc == 0 && h > 0
            handles(10) = h;
            foundJ1Name = gripperJ1Candidates{k};
            break;
        end
    end

    for k = 1:length(gripperJ2Candidates)
        [rc, h] = sim.simxGetObjectHandle(clientID, gripperJ2Candidates{k}, sim.simx_opmode_blocking);
        if rc == 0 && h > 0
            handles(11) = h;
            foundJ2Name = gripperJ2Candidates{k};
            break;
        end
    end

   
    fprintf('\n=== Handle Status ===\n');
    wheelNames = {'rollingJoint_rr','rollingJoint_rl','rollingJoint_fr','rollingJoint_fl'};
    armNames   = {'youBotArmJoint0','youBotArmJoint1','youBotArmJoint2','youBotArmJoint3','youBotArmJoint4'};
    for i = 1:4
        status = 'OK'; if handles(i) <= 0, status = 'WARN NOT FOUND'; end
        fprintf('  [%s] %s = %d\n', status, wheelNames{i}, handles(i));
    end
    for i = 1:5
        status = 'OK'; if handles(i+4) <= 0, status = 'WARN NOT FOUND'; end
        fprintf('  [%s] %s = %d\n', status, armNames{i}, handles(i+4));
    end

    if handles(10) > 0
        fprintf('  [OK]   gripperJoint1 = "%s" (handle %d)\n', foundJ1Name, handles(10));
    else
        fprintf('  [WARN] gripperJoint1 NOT FOUND\n');
        fprintf('         Открой CoppeliaSim > Scene Hierarchy, найди суставы гриппера\n');
        fprintf('         и добавь точное имя в gripperJ1Candidates в main.m\n');
    end
    if handles(11) > 0
        fprintf('  [OK]   gripperJoint2 = "%s" (handle %d)\n', foundJ2Name, handles(11));
    else
        fprintf('  [WARN] gripperJoint2 NOT FOUND\n');
    end
    fprintf('=====================\n\n');

    userGui = gui;
    userGui.sim      = sim;
    userGui.clientID = clientID;
    userGui.handles  = handles;
    userGui.setDefaultValues();

    if isvalid(userGui)
        waitfor(userGui);
    end

    sim.simxGetPingTime(clientID);
    sim.simxFinish(clientID);
else
    disp('Failed to connect to CoppeliaSim');
end

sim.delete();
disp('Done');
