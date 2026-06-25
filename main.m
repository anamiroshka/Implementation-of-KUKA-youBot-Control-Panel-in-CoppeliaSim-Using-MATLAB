clear
close all
clc

sim=remApi('remoteApi'); 
sim.simxFinish(-1);
clientID=sim.simxStart('127.0.0.1',19999,true,true,5000,5); 

if (clientID>-1) 
    disp('Connected to remote API server');

   handles = [0,0,0,0,0,0,0,0,0,0,0,0];

[~, handles(1)]=sim.simxGetObjectHandle(clientID,'rollingJoint_rr',sim.simx_opmode_blocking);
[~, handles(2)]=sim.simxGetObjectHandle(clientID,'rollingJoint_rl',sim.simx_opmode_blocking);
[~, handles(3)]=sim.simxGetObjectHandle(clientID,'rollingJoint_fr',sim.simx_opmode_blocking);
[~, handles(4)]=sim.simxGetObjectHandle(clientID,'rollingJoint_fl',sim.simx_opmode_blocking);
[~, handles(5)]=sim.simxGetObjectHandle(clientID,'youBotArmJoint0',sim.simx_opmode_blocking);
[~, handles(6)]=sim.simxGetObjectHandle(clientID,'youBotArmJoint1',sim.simx_opmode_blocking);
[~, handles(7)]=sim.simxGetObjectHandle(clientID,'youBotArmJoint2',sim.simx_opmode_blocking);
[~, handles(8)]=sim.simxGetObjectHandle(clientID,'youBotArmJoint3',sim.simx_opmode_blocking);
[~, handles(9)]=sim.simxGetObjectHandle(clientID,'youBotArmJoint4',sim.simx_opmode_blocking);


[~, handles(10)]=sim.simxGetObjectHandle(clientID,'youBotGripperJoint1',sim.simx_opmode_blocking);

[~, handles(11)]=sim.simxGetObjectHandle(clientID,'youBotGripperJoint2',sim.simx_opmode_blocking);

[~, handles(12)]=sim.simxGetObjectHandle(clientID,'visionSensor',sim.simx_opmode_blocking); userGui = gui;
    userGui.sim = sim;
    userGui.clientID = clientID;
    userGui.handles = handles;
    userGui.setDefaultValues();

    if isvalid(userGui)
        waitfor(userGui);
    end

    
    sim.simxGetPingTime(clientID);

    sim.simxFinish(clientID);
    endProgram(sim);
else 
    disp('Failed connecting to remote API server');
    endProgram(sim);
end

function endProgram(sim)
    sim.delete();
    disp('Program ended');
end