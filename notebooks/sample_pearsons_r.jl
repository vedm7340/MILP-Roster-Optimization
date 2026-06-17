x = [1, 2, 3, 4, 5]
y = [2, 4, 5, 4, 5]

x_mean = sum(x[i] for i in 1:5) / 5
println("X Mean: ", x_mean)

y_mean = sum(y[i] for i in 1:5) / 5
println("Y Mean: ", y_mean)

numerator = sum((x[i] - x_mean) * (y[i] - y_mean) for i in 1:5)
println("Numerator: ", numerator)

denominator = sqrt(sum((x[i] - x_mean)^2 for i in 1:5)) * sqrt(sum((y[i] - y_mean)^2 for i in 1:5))
println("Denominator: ", denominator)

pearsons_r = numerator/denominator
println("Pearsons R: ", pearsons_r)