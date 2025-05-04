-- Anti-Cheat System for Roblox
-- Designed for "Dead Rails" or similar games

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Create a RemoteEvent for reporting suspicious activity
local reportEvent = Instance.new("RemoteEvent")
reportEvent.Name = "ReportSuspiciousActivity"
reportEvent.Parent = ReplicatedStorage

-- Table to log suspicious activity
local suspiciousLogs = {}

-- Server-Side Anti-Cheat
Players.PlayerAdded:Connect(function(player)
    -- Initialize suspicious activity log for the player
    suspiciousLogs[player.UserId] = 0

    player.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")

        -- Example: Monitor WalkSpeed
        humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if humanoid.WalkSpeed > 16 then -- Default WalkSpeed is 16
                suspiciousLogs[player.UserId] += 1
                print("Cheating detected: " .. player.Name .. " - Illegal WalkSpeed")
                if suspiciousLogs[player.UserId] > 3 then
                    player:Kick("Cheating detected: Multiple offenses")
                end
            end
        end)

        -- Example: Monitor JumpPower
        humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if humanoid.JumpPower > 50 then -- Default JumpPower is 50
                suspiciousLogs[player.UserId] += 1
                print("Cheating detected: " .. player.Name .. " - Illegal JumpPower")
                if suspiciousLogs[player.UserId] > 3 then
                    player:Kick("Cheating detected: Multiple offenses")
                end
            end
        end)

        -- Monitor for impossible teleportation
        task.spawn(function()
            while character and character.PrimaryPart do
                local lastPosition = character.PrimaryPart.Position
                task.wait(1)
                local currentPosition = character.PrimaryPart.Position
                if (currentPosition - lastPosition).Magnitude > 100 then -- Example threshold
                    suspiciousLogs[player.UserId] += 1
                    print("Cheating detected: " .. player.Name .. " - Teleportation")
                    if suspiciousLogs[player.UserId] > 3 then
                        player:Kick("Cheating detected: Multiple offenses")
                    end
                end
            end
        end)
    end)
end)

-- Handle suspicious activity reports from clients
reportEvent.OnServerEvent:Connect(function(player, message)
    print("Suspicious activity reported by " .. player.Name .. ": " .. message)
    suspiciousLogs[player.UserId] += 1
    if suspiciousLogs[player.UserId] > 3 then
        player:Kick("Cheating detected: Multiple offenses")
    end
end)

-- Client-Side Anti-Cheat
local function clientAntiCheat()
    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local reportEvent = ReplicatedStorage:WaitForChild("ReportSuspiciousActivity")

    -- Example: Detect fly hacks by monitoring Y-axis movement
    local lastPosition = character.PrimaryPart.Position
    RunService.RenderStepped:Connect(function()
        local currentPosition = character.PrimaryPart.Position
        if (currentPosition.Y - lastPosition.Y) > 50 then -- Example threshold
            print("Fly hack detected")
            reportEvent:FireServer("Fly hack detected")
        end
        lastPosition = currentPosition
    end)
end

-- Run the client anti-cheat if this is a LocalScript
if RunService:IsClient() then
    clientAntiCheat()
end
