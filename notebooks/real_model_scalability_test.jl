# Packages needed to process the file and perform the staitstical calculations necessary
using CSV
using DataFrames
using Statistics

# Packages needed to create the optimization model
using JuMP
using HiGHS

# Package for the termination status of the model
using MathOptInterface
const MOI = MathOptInterface

# Importing the CSV file necessary for the model
df = CSV.read("C:/Users/vedan/OneDrive/Desktop/data/all_players_cleaned_three_point_percentage.csv", DataFrame)

# The amount of players that will be taken from the CSV File after each iteration
file_sizes = [70, 120, 170, 220, 270, 320, 370]

# Statistics Pearson's R Values. 
# Values were determined in the statistics_pearsons_r file where the average statistic of every team was compared across the team wins
ppg_r = 0.069
per_r = 0.165
ws_r = 0.937
games_r = 0.663
eFG_percent_r = 0.458
fouls_r = -0.477
turnovers_r = -0.599

# Adding up the absolute values of each Pearson's r coefficient
# abs function takes the absolute value of each variable
total_r = abs(ppg_r) + abs(per_r) + abs(ws_r) + abs(games_r) + abs(eFG_percent_r) + abs(fouls_r) + abs(turnovers_r)

# Standardization of each statistic. This way, statistics with higher Pearson's r coefficient will have higher precedence over other statistics.
# Additonally, this is a good baseline for each of the statistics
# round function rounds the value to a certain digit
ppg_w = round(ppg_r/total_r, digits=3)
per_w = round(per_r/total_r, digits=3)
ws_w = round(ws_r/total_r, digits=3)
games_w = round(games_r/total_r, digits=3)
eFG_percent_w = round(eFG_percent_r/total_r, digits=3)
fouls_w = round(fouls_r/total_r, digits=3)
turnovers_w = round(turnovers_r/total_r, digits=3)

# Fill any remaining missing numeric values with that column's mean
for col in names(df)
    if eltype(df[!, col]) <: Union{Missing, Number}
        col_mean = mean(skipmissing(df[!, col]))
        df[!, col] = coalesce.(df[!, col], col_mean)
    end
end

println("Pool Size | Objective Score | Solve Time (s) | Status")
println("-" ^ 55)

# Loop to run through the different file sizes that will be tested
for n in file_sizes
    # Local variables defined to prevent warning for assignment in soft scope
    local model
    local players
    local selected 
    local time_start
    local time_elapsed

    # Setting up the model
    model = Model(HiGHS.Optimizer)

    # suppress per-run HiGHS output for clean summary table
    set_silent(model)

    # Dataframe to store all of the players for each iteration
    players = first(df, n)

    # Binary variable to store the players the model selects
    @variable(model, selected[1:nrow(players)], Bin)

    # The objective function that takes all of the statistics and will be maxmimized in the model
    @objective(model, Max, sum((ppg_w * players.PTS[p] + per_w * players.PER[p] + ws_w * players.WS[p] + games_w * players.G[p] + eFG_percent_w * players[!, "eFG%"][p] + fouls_w * players.PF[p] + turnovers_w * players.TOV[p]) * selected[p] for p in 1:nrow(players)))

    # The official salary cap for every team in the 2025-26 NBA Season
    @constraint(model, sum(players.Salary[p] * selected[p] for p in 1:nrow(players)) <= 155)
    # The official salary floor for every team in the 2025-26 NBA Season
    @constraint(model, sum(players.Salary[p] * selected[p] for p in 1:nrow(players)) >= 139)

    # The maximum minutes all of the players from a team must play
    @constraint(model, sum(players.MP[p] * selected[p] for p in 1:nrow(players)) <= 240)
    # The minimum minutes all of the players from a team must play
    @constraint(model, sum(players.MP[p] * selected[p] for p in 1:nrow(players)) >= 220)

    # The minimum PGs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "PG") >= 2)
    # The maximum PGs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "PG") <= 3)

    # The minimum SGs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "SG") >= 2)
    # The maximum SGs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "SG") <= 3)

    # The minimum SFs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "SF") >= 2)
    # The maximum SFs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "SF") <= 3)

    # The minimum PFs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "PF") >= 2)
    # The maximum PFs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "PF") <= 3)

    # The minimum Cs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "C") >= 2)
    # The maximum Cs a team must roster
    @constraint(model, sum(selected[p] for p in 1:nrow(players) if players.Pos[p] == "C") <= 3)

    # The roster size of an NBA team
    @constraint(model, sum(selected[p] for p in 1:nrow(players)) == 15)

    # Variable to take in the start time of the model
    time_start = time()

    # Command to solve the model
    optimize!(model)

    # Variable to take in the total time elapsed during the optimization
    time_elapsed = time() - time_start
    # println("Time taken to solve the model: ", round(time_elapsed, digits=2))

    # If-else statement to check if the model is terminated. If not, then print out the results of this model
    if termination_status(model) != MOI.OPTIMAL
        println("Solver status: ",
                termination_status(model))
    else
        # Summary line for Table 3
        println("$n | $(round(objective_value(model),digits=4)) | $(round(time_elapsed,digits=2))s | Optimal")
    end
end