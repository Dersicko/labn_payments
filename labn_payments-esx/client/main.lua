RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(xPlayer)
	ESX.PlayerData = xPlayer
	ESX.PlayerLoaded = true
end)

RegisterNetEvent("esx:onPlayerLogout")
AddEventHandler("esx:onPlayerLogout", function()
	ESX.PlayerLoaded = false
	ESX.PlayerData = {}
end)

RegisterNetEvent("labn_payments:client:showMenuPayments", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local jobName = ""
        local SocietyEmergencys = false
        local SocietyBarsAndRestaurants = false
        for k, v in pairs(Config.SocietyEmergencys) do
            if v == ESX.PlayerData.job.name then
                jobName = v
                SocietyEmergencys = true
            end
        end
        for k, v in pairs(Config.SocietyBarsAndRestaurants) do
            if v == ESX.PlayerData.job.name then
                jobName = v
                SocietyBarsAndRestaurants = true
            end
        end
        local elements = {}
        table.insert(elements, {
            title = "📄 Invoices",
            description = "View My Unpaid Invoices",
            event = "labn_payments:client:ShowInvoicesStatusMenu"
        })
        table.insert(elements, {
            title = "📑 Fines",
            description = "View My Unpaid Fines",
            event = "labn_payments:client:ShowFinesStatusMenu"
        })
        if Config.SocietyEmergencys and SocietyEmergencys then
            table.insert(elements, {
                title = "📑 Create Custom Fine",
                description = "Create Fine to the Nearest Civilian",
                event = "labn_payments:client:CreateCustomFine"
            })
            table.insert(elements, {
                title = "📑 Check Fines",
                description = "Check Fines from the Nearest Civilian",
                event = "labn_payments:client:ShowFinesTargetStatusMenu"
            })
        elseif Config.SocietyBarsAndRestaurants and SocietyBarsAndRestaurants then
            table.insert(elements, {
                title = "📄 Create Invoice",
                description = "Create Invoice to Nearest Civilian",
                event = "labn_payments:client:CreateInvoice"
            })
            table.insert(elements, {
                title = "📄 Check Invoices",
                description = "Check Invoices from the nearest Civilian",
                event = "labn_payments:client:ShowInvoicesTargetStatusMenu"
            })
        end
        lib.registerContext({id = "show_payments_menu", title = "📑 Menu (Invoices / Fines)", options = elements})
        lib.showContext("show_payments_menu")
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesStatusMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local elements = {}
        table.insert(elements, {
            title = "📄 Unpaid Invoices",
            description = "View My Unpaid Invoices",
            event = "labn_payments:client:ShowInvoicesMenu"
        })
        table.insert(elements, {
            title = "📄 Paid Invoices",
            description = "View My Paid Invoices",
            event = "labn_payments:client:ShowInvoicesPaidMenu"
        })
        lib.registerContext({id = "show_invoices_status_menu", title = "📄 Invoices", menu = "show_payments_menu", options = elements})
        lib.showContext("show_invoices_status_menu")
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesStatusMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local elements = {}
        table.insert(elements, {
            title = "📑 Unpaid Fines",
            description = "View My Unpaid Fines",
            event = "labn_payments:client:ShowFinesMenu"
        })
        table.insert(elements, {
            title = "📑 Paid Fines",
            description = "View My Paid Fines",
            event = "labn_payments:client:ShowFinesPaidMenu"
        })
        lib.registerContext({id = "show_fines_status_menu", title = "📑 Fines", menu = "show_payments_menu", options = elements})
        lib.showContext("show_fines_status_menu")
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        ESX.TriggerServerCallback("labn_payments:server:getInvoices", function(invoices)
            if #invoices > 0 then
                local elements = {}
                for k, v in ipairs(invoices) do
                    table.insert(elements, {
                        title = ""..v.label.."",
                        description = "Invoice Amount: $"..ESX.Math.GroupDigits(v.amount).."",
                        event = "labn_payments:client:payInvoices",
                        metadata = {
                            {label = "Send Date", value = v.send_date},
                            {label = "Paid Date", value = v.paid_date},
                        },
                        args = {invoiceId = v.id}
                    })
                end
                lib.registerContext({id = "show_unpaid_invoices_menu", title = "Unpaid Invoices", menu = "show_invoices_status_menu", options = elements})
                lib.showContext("show_unpaid_invoices_menu")
            else
                lib.notify({description = "You Have No Invoice!", type = "inform"})
            end
        end)
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesPaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        ESX.TriggerServerCallback("labn_payments:server:getInvoicesPaid", function(invoices)
            if #invoices > 0 then
                local elements = {}
                for k, v in ipairs(invoices) do
                    table.insert(elements, {
                        title = ""..v.label.."",
                        description = "Invoice Amount: $"..ESX.Math.GroupDigits(v.amount).."",
                        metadata = {
                            {label = "Send Date", value = v.send_date},
                            {label = "Paid Date", value = v.paid_date},
                        },
                        args = {invoiceId = v.id}
                    })
                end
                lib.registerContext({id = "show_paid_invoices_menu", title = "Paid Invoices", menu = "show_invoices_status_menu", options = elements})
                lib.showContext("show_paid_invoices_menu")
            else
                lib.notify({description = "You Have No Invoice!", type = "inform"})
            end
        end)
    end
end)

RegisterNetEvent("labn_payments:client:CreateInvoice", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            local input = lib.inputDialog("Create Invoice", {"Invoice Label", "Invoice Amount"})
            if input then
                local Invoicelabel = input[1]
                local InvoiceAmount = tonumber(input[2])
                if InvoiceAmount <= 0 then
                    return lib.notify({description = "Invalid Amount!", type = "error"})
                end
                TriggerServerEvent("labn_payments:server:sendInvoice", GetPlayerServerId(closestPlayer), Invoicelabel, InvoiceAmount, "society_"..ESX.PlayerData.job.name.."")
            end
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:payInvoices", function(data)
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        selectedInvoice = data.invoiceId
        local alert = lib.alertDialog({
            header = "Do you really want to pay that invoice?",
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            ESX.TriggerServerCallback("labn_payments:server:payInvoice", function()
                TriggerEvent("labn_payments:client:ShowInvoicesMenu")
            end, selectedInvoice)
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesTargetStatusMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            local elements = {}
            table.insert(elements, {
                title = "📄 Unpaid Invoices",
                description = "View Target Unpaid Invoices",
                event = "labn_payments:client:ShowInvoicesTargetUnpaidMenu"
            })
            table.insert(elements, {
                title = "📄 Paid Invoices",
                description = "View Target Paid Invoices",
                event = "labn_payments:client:ShowInvoicesTargetPaidMenu"
            })
            lib.registerContext({id = "show_invoices_target_status_menu", title = "📄 Invoices", menu = "show_payments_menu", options = elements})
            lib.showContext("show_invoices_target_status_menu")
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesTargetUnpaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            ESX.TriggerServerCallback("labn_payments:server:getTargetInvoices", function(invoices)
                if #invoices > 0 then
                    local elements = {}
                    for k, invoice in ipairs(invoices) do
                        table.insert(elements, {
                            title = ""..invoice.label.."",
                            description = "Invoice Amount: $"..ESX.Math.GroupDigits(invoice.amount).."",
                            metadata = {
                                {label = "Send Date", value = invoice.send_date},
                                {label = "Paid Date", value = invoice.paid_date},
                            },
                            args = {invoiceId = invoice.id}
                        })
                    end
                    lib.registerContext({id = "show_invoices_target_unpaid_menu", title = "Unpaid Invoices", menu = "show_invoices_target_status_menu", options = elements})
                    lib.showContext("show_invoices_target_unpaid_menu")
                else
                    lib.notify({description = "This Civilian has no Invoice!", type = "inform"})
                end
            end, GetPlayerServerId(closestPlayer))
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowInvoicesTargetPaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            ESX.TriggerServerCallback("labn_payments:server:getTargetInvoicesPaid", function(invoices)
                if #invoices > 0 then
                    local elements = {}
                    for k, invoice in ipairs(invoices) do
                        table.insert(elements, {
                            title = ""..invoice.label.."",
                            description = "Invoice Amount: $"..ESX.Math.GroupDigits(invoice.amount).."",
                            metadata = {
                                {label = "Send Date", value = invoice.send_date},
                                {label = "Paid Date", value = invoice.paid_date},
                            },
                            args = {invoiceId = invoice.id}
                        })
                    end
                    lib.registerContext({id = "show_invoices_target_paid_menu", title = "Paid Invoices", menu = "show_invoices_target_status_menu", options = elements})
                    lib.showContext("show_invoices_target_paid_menu")
                else
                    lib.notify({description = "This Civilian has no Invoice!", type = "inform"})
                end
            end, GetPlayerServerId(closestPlayer))
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        ESX.TriggerServerCallback("labn_payments:server:getFines", function(fines)
            if #fines > 0 then
                local elements = {}
                for k, v in ipairs(fines) do
                    table.insert(elements, {
                        title = ""..v.label.."",
                        description = "Fine Amount: $"..ESX.Math.GroupDigits(v.amount).."",
                        event = "labn_payments:client:payFines",
                        metadata = {
                            {label = "Send Date", value = v.send_date},
                            {label = "Paid Date", value = v.paid_date},
                        },
                        args = {fineId = v.id}
                    })
                end
                lib.registerContext({id = "show_fines_menu", title = "Unpaid Fines", menu = "show_fines_status_menu", options = elements})
                lib.showContext("show_fines_menu")
            else
                lib.notify({description = "You Have No Fines!", type = "inform"})
            end
        end)
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesPaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        ESX.TriggerServerCallback("labn_payments:server:getFinesPaid", function(fines)
            if #fines > 0 then
                local elements = {}
                for k, v in ipairs(fines) do
                    table.insert(elements, {
                        title = ""..v.label.."",
                        description = "Fine Amount: $"..ESX.Math.GroupDigits(v.amount).."",
                        metadata = {
                            {label = "Send Date", value = v.send_date},
                            {label = "Paid Date", value = v.paid_date},
                        },
                        args = {fineId = v.id}
                    })
                end
                lib.registerContext({id = "show_paid_fines_menu", title = "Paid Fines", menu = "show_fines_status_menu", options = elements})
                lib.showContext("show_paid_fines_menu")
            else
                lib.notify({description = "You Have No Fines!", type = "inform"})
            end
        end)
    end
end)

RegisterNetEvent("labn_payments:client:CreateCustomFine", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            local input = lib.inputDialog("Create Fine", {"Fine Label", "Fine Amount"})
            if input then
                local labelFine = input[1]
                local amountFine = tonumber(input[2])
                if amountFine == 0 then
                    return lib.notify({description = "Invalid Amount!", type = "error"})
                end
                TriggerServerEvent("labn_payments:server:sendFine", GetPlayerServerId(closestPlayer), labelFine, amountFine, "society_"..ESX.PlayerData.job.name.."")
            end
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:payFines", function(data)
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        selectedFine = data.fineId
        local alert = lib.alertDialog({
            header = "Do you really want to pay that fine?",
            centered = true,
            cancel = true
        })
        if alert == "confirm" then
            ESX.TriggerServerCallback("labn_payments:server:payFine", function()
                TriggerEvent("labn_payments:client:ShowFinesMenu")
            end, selectedFine)
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesTargetStatusMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            local elements = {}
            table.insert(elements, {
                title = "📑 Unpaid Fines",
                description = "View Target Unpaid Fines",
                event = "labn_payments:client:ShowFinesTargetUnpaidMenu"
            })
            table.insert(elements, {
                title = "📑 Paid Fines",
                description = "View Target Paid Fines",
                event = "labn_payments:client:ShowFinesTargetPaidMenu"
            })
            lib.registerContext({id = "show_fines_target_status_menu", title = "📑 Fines", menu = "show_payments_menu", options = elements})
            lib.showContext("show_fines_target_status_menu")
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesTargetUnpaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            ESX.TriggerServerCallback("labn_payments:server:getTargetFines", function(fines)
                if #fines > 0 then
                    local elements = {}
                    for k, fine in ipairs(fines) do
                        table.insert(elements, {
                            title = ""..fine.label.."",
                            description = "Fine Amount: $"..ESX.Math.GroupDigits(fine.amount).."",
                            metadata = {
                                {label = "Send Date", value = fine.send_date},
                                {label = "Paid Date", value = fine.paid_date},
                            },
                            args = {fineId = fine.id}
                        })
                    end
                    lib.registerContext({id = "show_fines_target_unpaid_menu", title = "Unpaid Fines", menu = "show_fines_target_status_menu", options = elements})
                    lib.showContext("show_fines_target_unpaid_menu")
                else
                    lib.notify({description = "This Civilian has no Fines!", type = "inform"})
                end
            end, GetPlayerServerId(closestPlayer))
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterNetEvent("labn_payments:client:ShowFinesTargetPaidMenu", function()
    if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
		if closestPlayer ~= -1 and closestDistance <= 3.0 then
            ESX.TriggerServerCallback("labn_payments:server:getTargetFinesPaid", function(fines)
                if #fines > 0 then
                    local elements = {}
                    for k, fine in ipairs(fines) do
                        table.insert(elements, {
                            title = ""..fine.label.."",
                            description = "Fine Amount: $"..ESX.Math.GroupDigits(fine.amount).."",
                            metadata = {
                                {label = "Send Date", value = fine.send_date},
                                {label = "Paid Date", value = fine.paid_date},
                            },
                            args = {fineId = fine.id}
                        })
                    end
                    lib.registerContext({id = "show_fines_target_paid_menu", title = "Unpaid Fines", menu = "show_fines_target_status_menu", options = elements})
                    lib.showContext("show_fines_target_paid_menu")
                else
                    lib.notify({description = "This Civilian has no Fines!", type = "inform"})
                end
            end, GetPlayerServerId(closestPlayer))
        else
            lib.notify({description = "No Civilians Nearby!", type = "error"})
        end
    end
end)

RegisterCommand("showMenuPayments", function()
	if ESX.PlayerLoaded and not ESX.PlayerData.dead then
        TriggerEvent("labn_payments:client:showMenuPayments")
	end
end)

RegisterKeyMapping("showMenuPayments", "Show Menu (Invoices / Fines)", "keyboard", "F7")