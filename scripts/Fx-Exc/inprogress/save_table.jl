dir_file_10 = datadir(
    "guatemala",
    "Guatemala_GB_2010.csv"
)

tab_10 = @chain datadir("guatemala", dir_file_10) begin
    open(read, _, enc"ISO-8859-1")
    CSV.File
    DataFrame
end

tab_10.num = 1:length(tab_10.Codigo)

tab_10_r = tab_10[exc_opt[2], :]

tab_10_r = @chain tab_10_r begin
    select(_, [:num, :GastoBasico])   
end

open("output.txt", "w") do f
    pretty_table(f, tab_10_r, tf = tf_markdown)
end