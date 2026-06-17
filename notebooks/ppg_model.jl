using JuMP
using HiGHS

model = Model(HiGHS.Optimizer)

players = ["N. Jokic", "J. Murray", "M. Porter Jr.", "A. Gordon", "B. Hyland", "K. Caldwell-Pope", "R. Jackson", "J. Green", "Z. Nnaji", "D. Jordan", "V. Cancar", "C. Braun"]
ppg = Dict("N. Jokic" => 24.5, "J. Murray" => 20.0, "M. Porter Jr." => 17.4, "A. Gordon" => 16.3, "B. Hyland" => 12.1, "K. Caldwell-Pope" => 10.8, "R. Jackson" => 7.9, "J. Green" => 7.8, "Z. Nnaji" => 5.2, "D. Jordan" => 5.1, "V. Cancar" => 5, "C. Braun" => 4.7)
salary = Dict("N. Jokic" => 33.0, "J. Murray" => 31.7, "M. Porter Jr." => 30.9, "A. Gordon" => 19.7, "B. Hyland" => 2.2, "K. Caldwell-Pope" => 14.0, "R. Jackson" => 0.6, "J. Green" => 4.5, "Z. Nnaji" => 2.6, "D. Jordan" => 1.8, "V. Cancar" => 2.2, "C. Braun" => 2.8)

@variable(model, selected[players], Bin)

@objective(model, Max, sum(ppg[p] * selected[p] for p in players))

@constraint(model, sum(salary[p] * selected[p] for p in players) <= 100)
@constraint(model, sum(selected[p] for p in players) == 7)

optimize!(model)

selected_players = [
    p for p in players
    if value(selected[p]) > 0.5
]

println("Selected Players: ", selected_players)
println("Total PPG: ", objective_value(model))