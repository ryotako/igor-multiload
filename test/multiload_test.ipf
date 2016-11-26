#include "MinTest"
#include "multiload"

static Function setup()
	NewDataFolder/O root:Packages
	NewDataFolder/O root:Packages:TestMultiload
	cd root:Packages:TestMultiload
End

static Function teardown()
	cd root:
	KillDataFolder root:Packages:TestMultiload
End

Function TestMultiLoad()
	setup()
	String path = RemoveEnding(FunctionPath(""), "multiload_test.ipf")
	Make/FREE/T/N=6 files = path
	files[0] += "sampleA_100K_a-axis.dat"
	files[1] += "sampleA_200K_a-axis.dat"
	files[2] += "sampleA_300K_a-axis.dat"
	files[3] += "sampleA_100K_a-axis.dat"
	files[4] += "sampleA_200K_a-axis.dat"
	files[5] += "sampleA_300K_a-axis.dat"
	
	
	multiload#MultiLoadImplement(files, {"_"}, "LoadWave/A/D/G/Q %P", "%B")
	
	
//	teardown()
End

Function TestPathUtils()
	eq_str(multiload#ExpandExpr("%B","test.dat"), "\"test\"")
	eq_str(multiload#ExpandExpr("%P","path:test.dat"), "\"path:test.dat\"")

	eq_str(multiload#extension("test.dat"), "dat")
	eq_str(multiload#extension("path:test.dat"), "dat")
	
	eq_str(multiload#basename("test.dat"), "test")
	eq_str(multiload#basename("path:test.dat"), "test")
	eq_str(multiload#basename("this:is:a:test.dat"), "test")
	
	eq_str(multiload#filename("test.dat"), "test.dat")
	eq_str(multiload#filename("path:test.dat"), "test.dat")
	eq_str(multiload#filename("this:is:a:test.dat"), "test.dat")
	
	eq_str(multiload#dirname("test.dat"), "")
	eq_str(multiload#dirname("path:test.dat"), "path:")
	eq_str(multiload#dirname("this:is:a:test.dat"), "this:is:a:")	
End

Function TestSplitLine()
	eq_text(multiload#SplitLine("a_b_c", {"_"}), {"a", "b", "c"})
	eq_text(multiload#SplitLine("a_b:c", {"_", ":"}), {"a", "b", "c"})
End

Function TestMatrix()
	eq_text(multiload#FileNameMatrix(1, {"a_1","b_2"}, {"_"}, "%B"), $"")
	eq_text(multiload#FileNameMatrix(2, {"a_1","b_2"}, {"_"}, "%B"), {{"a", "1"}, {"b", "2"}})
	eq_text(multiload#FileNameMatrix(3, {"a_1","b_2"}, {"_"}, "%B"), $"")

	Make/FREE/T/N=6 w
	w[0] = "Macintosh HD:Users:XXX:Desktop:test:sampleA_100K_a-axis.dat"
	w[1] = "Macintosh HD:Users:XXX:Desktop:test:sampleA_200K_a-axis.dat"
	w[2] = "Macintosh HD:Users:XXX:Desktop:test:sampleA_300K_a-axis.dat"
	w[3] = "Macintosh HD:Users:XXX:Desktop:test:sampleB_100K_a-axis.dat"
	w[4] = "Macintosh HD:Users:XXX:Desktop:test:sampleB_200K_a-axis.dat"
	w[5] = "Macintosh HD:Users:XXX:Desktop:test:sampleB_300K_a-axis.dat"
	Make/FREE/T/N=(3,6) ans
	ans[0][0]= {"sampleA","100K","a-axis"}
	ans[0][1]= {"sampleA","200K","a-axis"}
	ans[0][2]= {"sampleA","300K","a-axis"}
	ans[0][3]= {"sampleB","100K","a-axis"}
	ans[0][4]= {"sampleB","200K","a-axis"}
	ans[0][5]= {"sampleB","300K","a-axis"}
	eq_text(multiload#FileNameMatrix(3, w, {"_", " "}, "%B"), ans)
	
	

	eq_text(multiload#SortRows({{"a", "1"}, {"b", "1"}, {"c", "1"}}), {{"1", "a"}, {"1", "b"}, {"1", "c"}})
	eq_text(multiload#SortRows({{"a", "1"}, {"a", "2"}, {"a", "3"}}), {{"a", "1"}, {"a", "2"}, {"a", "3"}})

	eq_text(multiload#JoinRows({{"a", "1", "x"}, {"a", "1", "y"}}), {{"a_1", "x"}, {"a_1", "y"}})
End