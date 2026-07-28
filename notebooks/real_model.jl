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

# Fill any remaining missing numeric values with that column's mean
for col in names(df)
    if eltype(df[!, col]) <: Union{Missing, Number}
        col_mean = mean(skipmissing(df[!, col]))
        df[!, col] = coalesce.(df[!, col], col_mean)
    end
end

# Setting up the model
model = Model(HiGHS.Optimizer)

# Create an array to store all of the player names
players = df.Player

# Create a dictionary to store each of the player's position
players_position = Dict(df.Player .=> df.Pos)

# Create dictionaries to store each of the player's statistics
players_ppg = Dict(df.Player .=> df.PTS)
players_per = Dict(df.Player .=> df.PER)
players_ws = Dict(df.Player .=> df.WS)
players_threepoint_percent = Dict(df.Player .=> df[!, "3P%"])
players_assists = Dict(df.Player .=> df.AST)
players_games = Dict(df.Player .=> df.G)
players_fouls = Dict(df.Player .=> df.PF)

# Create dictionaries to store each of the player's salary and minutes played
players_salary = Dict(df.Player .=> df.Salary)
players_mins = Dict(df.Player .=> df.MP)

# Binary variable to store the players the model selects
@variable(model, selected[players], Bin)

# Statistics Pearson's R Values. 
# Values were determined in the statistics_pearsons_r file where the average statistic of every team was compared across the team wins
ppg_r = 0.494
per_r = 0.517
ws_r = 0.725
threepoint_percent_r = 0.337
assists_r = 0.292
games_r = 0.195
fouls_r = -0.301

# Adding up the absolute values of each Pearson's r coefficient
# abs function takes the absolute value of each variable
total_r = abs(ppg_r) + abs(per_r) + abs(ws_r) + abs(threepoint_percent_r) + abs(assists_r) + abs(games_r) + abs(fouls_r)

# Standardization of each statistic. This way, statistics with higher Pearson's r coefficient will have higher precedence over other statistics.
# Additonally, this is a good baseline for each of the statistics
# round function rounds the value to a certain digit
ppg_w = round(ppg_r/total_r, digits=3)
per_w = round(per_r/total_r, digits=3)
ws_w = round(ws_r/total_r, digits=3)
threepoint_percent_w = round(threepoint_percent_r/total_r, digits=3)
assists_w = round(assists_r/total_r, digits=3)
games_w = round(games_r/total_r, digits=3)
fouls_w = round(fouls_r/total_r, digits=3)

# The objective function that takes all of the statistics and will be maxmimized in the model
@objective(model, Max, sum((ppg_w * players_ppg[p] + per_w * players_per[p] + ws_w * players_ws[p] + threepoint_percent_w * players_threepoint_percent[p] + assists_w * players_assists[p] + games_w * players_games[p] + fouls_w * players_fouls[p]) * selected[p] for p in players))

# 2025-26 NBA salary cap: $155M upper bound
@constraint(model, sum(players_salary[p] * selected[p] for p in players) <= 155)
# 2025-26 NBA luxury tax threshold: $139M lower bound (salary floor)
@constraint(model, sum(players_salary[p] * selected[p] for p in players) >= 139)

# The maximum minutes all of the players from a team must play
@constraint(model, sum(players_mins[p] * selected[p] for p in players) <= 240)
# The minimum minutes all of the players from a team must play
@constraint(model, sum(players_mins[p] * selected[p] for p in players) >= 220)

# The minimum number of PGs a team must roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "PG") >= 2)
# The maximum number of PGs a team may roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "PG") <= 3)

# The minimum number of SGs a team must roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "SG") >= 2)
# The maximum number of SGs a team may roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "SG") <= 3)

# The minimum number of SFs a team must roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "SF") >= 2)
# The maximum number of SFs a team may roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "SF") <= 3)

# The minimum number of PFs a team must roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "PF") >= 2)
# The maximum number of PFs a team may roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "PF") <= 3)

# The minimum number of Cs a team must roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "C") >= 2)
# The maximum number of Cs a team may roster
@constraint(model, sum(selected[p] for p in players if players_position[p] == "C") <= 3)

# The roster size of an NBA team
@constraint(model, sum(selected[p] for p in players) == 15)

# Variable to take in the start time of the model
time_start = time()

# Command to solve the model
optimize!(model)

# Variable to take in the total time elapsed during the optimization
time_elapsed = time() - time_start
println("Time taken to solve the model: ", round(time_elapsed, digits=2))

# If-else statement to check if the model is terminated. If not, then print out the results of this model
if termination_status(model) != MOI.OPTIMAL
    println("Solver status: ",
        termination_status(model))
else
    # Array to store the players that the model selects
    selected_players = [
        p for p in players
        if value(selected[p]) > 0.5
    ]

    # Print out the results of the model
    println("Selected Players: ", selected_players)
    println("Selected Players PPG: ", [players_ppg[p] for p in selected_players])
    println("Selected Players PER: ", [players_per[p] for p in selected_players])
    println("Selected Players WS: ", [players_ws[p] for p in selected_players])
    println("Selected Players 3P%: ", [players_threepoint_percent[p] for p in selected_players])
    println("Selected Players APG: ", [players_assists[p] for p in selected_players])
    println("Selected Players Total Games Played: ", [players_games[p] for p in selected_players])
    println("Selected Players FPG: ", [players_fouls[p] for p in selected_players])

    # Print out the averages for each statistic and the objective score
    println("Objective Score: ", round(objective_value(model), digits=4))
    println("Average Points: ", round(sum(players_ppg[p] for p in selected_players)/length(selected_players), digits=1))
    println("Average PER: ", round(sum(players_per[p] for p in selected_players)/length(selected_players), digits=1))
    println("Average WS: ", round(sum(players_ws[p] for p in selected_players)/length(selected_players), digits=1))
    println("Average 3P%: ", round(sum(players_threepoint_percent[p] for p in selected_players)/length(selected_players), digits=3))
    println("Average APG: ", round(sum(players_assists[p] for p in selected_players)/length(selected_players), digits=1))
    println("Average Games Played: ", round(sum(players_games[p] for p in selected_players)/length(selected_players), digits=1))
    println("Average FPG: ", round(sum(players_fouls[p] for p in selected_players)/length(selected_players), digits=1))

    # Check the constraints
    println("Total Selected Players: ", length(selected_players))
    println("Total Salary (M): ", round(sum(players_salary[p] for p in selected_players), digits=2))
    println("Total Minutes: ", sum(players_mins[p] for p in selected_players))
end