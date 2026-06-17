using JuMP
using HiGHS

model = Model(HiGHS.Optimizer)

players = ["N. Jokic", "J. Murray", "M. Porter Jr.", "A. Gordon", "B. Hyland", "K. Caldwell-Pope", "R. Jackson", "J. Green", "Z. Nnaji", "D. Jordan", "V. Cancar", "C. Braun"]
ws = Dict("N. Jokic" => 14.9, "J. Murray" => 5.1, "M. Porter Jr." => 4.3, "A. Gordon" => 6.8, "B. Hyland" => 0.9, "K. Caldwell-Pope" => 4.5, "R. Jackson" => 0.1, "J. Green" => 1.7, "Z. Nnaji" => 1.6, "D. Jordan" => 1.4, "V. Cancar" => 1.7, "C. Braun" => 1.9)
salary = Dict("N. Jokic" => 33.0, "J. Murray" => 31.7, "M. Porter Jr." => 30.9, "A. Gordon" => 19.7, "B. Hyland" => 2.2, "K. Caldwell-Pope" => 14.0, "R. Jackson" => 0.6, "J. Green" => 4.5, "Z. Nnaji" => 2.6, "D. Jordan" => 1.8, "V. Cancar" => 2.2, "C. Braun" => 2.8)

@variable(model, selected[players], Bin)

@objective(model, Max, sum(ws[p] * selected[p] for p in players))

@constraint(model, sum(salary[p] * selected[p] for p in players) <= 100)
@constraint(model, sum(selected[p] for p in players) == 7)

optimize!(model)

selected_players = [
    p for p in players
    if value(selected[p]) > 0.5
]

println("Selected Players: ", selected_players)
println("Total WS: ", objective_value(model))