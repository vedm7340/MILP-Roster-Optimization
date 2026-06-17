using JuMP
using HiGHS

model = Model(HiGHS.Optimizer)

players = ["N. Jokic", "J. Murray", "M. Porter Jr.", "A. Gordon", "B. Hyland", "K. Caldwell-Pope", "R. Jackson", "J. Green", "Z. Nnaji", "D. Jordan", "V. Cancar", "C. Braun"]
per = Dict("N. Jokic" => 31.5, "J. Murray" => 17.9, "M. Porter Jr." => 16.8, "A. Gordon" => 19.5, "B. Hyland" => 14.4, "K. Caldwell-Pope" => 11.5, "R. Jackson" => 8.9, "J. Green" => 11.0, "Z. Nnaji" => 12.6, "D. Jordan" => 14.8, "V. Cancar" => 11.0, "C. Braun" => 10.3)
salary = Dict("N. Jokic" => 33.0, "J. Murray" => 31.7, "M. Porter Jr." => 30.9, "A. Gordon" => 19.7, "B. Hyland" => 2.2, "K. Caldwell-Pope" => 14.0, "R. Jackson" => 0.6, "J. Green" => 4.5, "Z. Nnaji" => 2.6, "D. Jordan" => 1.8, "V. Cancar" => 2.2, "C. Braun" => 2.8)

@variable(model, selected[players], Bin)

@objective(model, Max, sum(per[p] * selected[p] for p in players))

@constraint(model, sum(salary[p] * selected[p] for p in players) <= 100)
@constraint(model, sum(selected[p] for p in players) == 7)

optimize!(model)

selected_players = [
    p for p in players
    if value(selected[p]) > 0.5
]

println("Selected Players: ", selected_players)
println("Total PER: ", objective_value(model))