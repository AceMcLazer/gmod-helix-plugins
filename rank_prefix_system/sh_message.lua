--  StarLight's Chat Message System, Very useful.
if SERVER then
    local meta = FindMetaTable("Player")

    util.AddNetworkString("sl_chat_system")

    function meta:SLChatMessage(tbl)
        net.Start("sl_chat_system")
          net.WriteTable(tbl)
         net.Send(self)
    end

    function SLChatMessage(tbl)
        net.Start("sl_chat_system")
            net.WriteTable(tbl)
        net.Broadcast()
    end
else
    net.Receive("sl_chat_system", function()
        chat.AddText(unpack(net.ReadTable()))
    end)
end