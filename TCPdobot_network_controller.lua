-- File: advanced_server.lua

local ip = "192.168.2.6"
local port = 3500
local socket = 0
local err = 0
local incomming_data = {}
local i = 1

-- Encryption/Decryption Key (Should be kept secret!)
local key = 0xAF

-- Encryption and Decryption function using XOR
local function crypt(data)
    local result = {}
    for i = 1, #data do
        result[i] = string.char(bit32.bxor(data:byte(i), key))
    end
    return table.concat(result)
end

-- Robust error handler
local function error_handler(message)
    print("[ERROR] " .. message .. " - Reconnecting...")
    TCPDestroy(socket)
    Sleep(1000)
    goto create_server
end

while true do
    ::create_server::
    err, socket = TCPCreate(true, ip, port)
    if err ~= 0 then error_handler("Failed to create socket") end

    err = TCPStart(socket, 0)
    if err ~= 0 then error_handler("Failed to start server") end

    while true do
        err, buf = TCPRead(socket, 0, "string")
        if err ~= 0 then
            error_handler("Failed to read data")
            break
        end

        local data = crypt(buf.buf)
        local tokens = {}
        for token in string.gmatch(data, "[^%s]+") do
            table.insert(tokens, token)
        end

        if tokens[1] == "j1" then
            local joint_1, joint_2, joint_3, joint_4 = tonumber(tokens[2]), tonumber(tokens[4]), tonumber(tokens[6]), tonumber(tokens[8])
            joint_1 = math.max(math.min(joint_1, 0), -90)
            joint_2 = math.max(math.min(joint_2, 55), -20)
            joint_3 = math.max(math.min(joint_3, 70), -20)
            joint_4 = tonumber(joint_4)

            print(string.format("Moving joints to: J1=%d, J2=%d, J3=%d, J4=%d", joint_1, joint_2, joint_3, joint_4))
            JointMovJ(({ joint = {joint_1, joint_2, joint_3, joint_4} }))
        elseif tokens[1] == "x" then
            local MX, MY, MZ, MR = tonumber(tokens[2]), tonumber(tokens[4]), tonumber(tokens[6]), tonumber(tokens[8])
            MX = math.max(math.min(MX, 350), 220)
            MY = math.max(math.min(MY, 250), 0)
            MZ = math.max(math.min(MZ, 150), -150)

            print(string.format("Moving coordinates to: MX=%d, MY=%d, MZ=%d, MR=%d", MX, MY, MZ, MR))
            MovJ(({ coordinate = {MX, MY, MZ, MR}, tool = 0, user = 0 }))
        elseif tokens[1] == "get" then
            local response_data = string.format("s,%s,%s,%s,%s,%s,%s,%s,%s",
                GetAngle().joint[1], GetAngle().joint[2], GetAngle().joint[3], GetAngle().joint[4],
                GetPose().coordinate[1], GetPose().coordinate[2], GetPose().coordinate[3], GetPose().coordinate[4])
            TCPWrite(socket, crypt(response_data))
        else
            print("[WARNING] Unrecognized command received: " .. tokens[1])
        end
    end
end
