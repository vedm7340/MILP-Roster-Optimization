# Packages needed to process the CSV file and perform the staitstical calculations necessary
using CSV
using DataFrames
using Statistics

# Importing the CSV file necessary for the model
df = CSV.read("C:/Users/vedan/OneDrive/Desktop/data/all_players_cleaned_three_point_percentage.csv", DataFrame)

# Fill any remaining missing numeric values with that column's mean
for col in names(df)
    if eltype(df[!, col]) <: Union{Missing, Number}
        col_mean = mean(skipmissing(df[!, col]))
        df[!, col] = coalesce.(df[!, col], col_mean)
    end
end

# Setting up the salary cap, roster size, and total minutes manually instead of JuMP syntax
roster_size = 15
salary_cap = 155
total_minutes = 0 # Resets to 0 each run - declare as local variable if wrapping in a function

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

# Composite score for each player: weighted sum of all 7 metrics
# using Pearson's r normalized weights (w_ values above)
# Higher score indicates greater expected contribution to team wins
df[!, "Score"] = ppg_w .* df[!, "PTS"] .+ per_w .* df[!, "PER"] .+ ws_w .* df[!, "WS"] .+ games_w .* df[!, "G"] .+ eFG_percent_w .* df[!, "eFG%"] .+ fouls_w .* df[!, "PF"] .+ turnovers_w .* df[!, "TOV"]

# Sorting by this heuristic prioritizes players with higher value for their dollar which differentiates this algorithm from greedy
df[!, "ValuePerDollar"] = df[!, "Score"] ./ df[!, "Salary"]
sort!(df, "ValuePerDollar", rev=true)

# DataFrame that will store the selected players and variable that will store the remaining cap after each iteration
selected_players = similar(df, 0)
remaining_cap = salary_cap

# Variable to take in the start time of the model
time_start = time()

# For-Loop to iterate through the players
for row in eachrow(df)
    # If the amount of selected players reaches 15, end the for-loop
    if nrow(selected_players) == roster_size
        break
    end
    
    # If the next player's salary is lesser than the remaining cap and their minutes won't push the total minutes above 240, then push that player onto the selected players DataFrame, subtract their salary from the remaining cap, and add their minutes to the total minutes
    if row.Salary <= remaining_cap && total_minutes + row.MP <= 240
        # Position constraint: maximum 3 players per position allowed
        # count(==(row.Pos), selected_players.Pos) counts how many players
        # at that position are already on the roster
        # Prevents selecting 15 guards regardless of their value
        if count(==(row.Pos), selected_players.Pos) < 3
            push!(selected_players, row)
            global remaining_cap -= row.Salary
            global total_minutes += row.MP
        end
    end
end

# Variable to take in the total time elapsed during the optimization
time_elapsed = time() - time_start
println("Time taken to solve the model (ms): ", round(time_elapsed * 1000, digits=3))

# If the total minutes of all of the players is below 220 (the minimum amount), then print out the warning that the minutes constraint wasn't satisfied
if total_minutes < 220
    println("Warning: minutes constraint not satisfied! Total: $total_minutes")
end

# To implement the minimum salary cap in this algorithm, this if statement is written.
if (salary_cap - remaining_cap) < 139
    println("Warning: salary cap constraint not satisfied! Total: $(salary_cap - remaining_cap)")
end

# Print out all of the results.
println("Selected Players: ", selected_players.Player)
println("Selected Players PPG: ", selected_players.PTS)
println("Selected Players PER: ", selected_players.PER)
println("Selected Players WS: ", selected_players.WS)
println("Selected Players Total Games Played: ", selected_players.G)
println("Selected Players eFG%: ", selected_players[!, "eFG%"])
println("Selected Players FPG: ", selected_players.PF)
println("Selected Players TPG: ", selected_players.TOV)

heuristic_score = sum(selected_players[!, "Score"])
println("Heuristic Objective Score: ", round(heuristic_score, digits=4))

println("Average PPG: ", round(sum(selected_players.PTS)/nrow(selected_players), digits=1))
println("Average PER: ", round(sum(selected_players.PER)/nrow(selected_players), digits=1))
println("Average WS: ", round(sum(selected_players.WS)/nrow(selected_players), digits=1))
println("Average Games Played: ", round(sum(selected_players.G)/nrow(selected_players), digits=1))
println("Average eFG%: ", round(sum(selected_players[!, "eFG%"])/nrow(selected_players), digits=3))
println("Average FPG: ", round(sum(selected_players.PF)/nrow(selected_players), digits=1))
println("Average TPG: ", round(sum(selected_players.TOV)/nrow(selected_players), digits=1))

println("Total Selected Players: ", nrow(selected_players))
println("Total Salary (M): ", round(sum(selected_players.Salary), digits=2))
println("Total Minutes: ", sum(selected_players.MP))