#pragma ModuleName=Multiload
strconstant Multiload_Menu="Multiload"

////////////////////////////////////////////////////////////////////////////////
// Prototype Settings //////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Menu: Standard Setting (*.dat, *.txt)
Function Multiload_Standard_Setting()
	STRUCT Multiload ml
	ml.command    = "LoadWave/A/D/G/Q %P; KillVariables/Z V_Flag; KillStrings/Z S_waveNames"
	ml.dirhint    = "%B" // filename used to make directory-hierarchy in Igor
	ml.filetype   = "Data Files"
	ml.extensions = ".dat;.txt"
	ml.delimiters = "_; "
	ml.load(ml)
End

// Menu: General Setting (Dialog)
Function Multiload_General_Setting()
	STRUCT Multiload ml
	String command= "LoadWave/A/D/G/Q %P; KillVariables/Z V_Flag; KillStrings/Z S_waveNames"
	Prompt command, "Command for loading waves"
	String dirhint= "%B"    
	Prompt dirhint, "String for creating directory tree"
	String filetype= "Data Files"  
	Prompt filetype, "File type"
	String extensions= ".dat;.txt"
	Prompt extensions, "Extensions (list)"
	String delimiters= " ;_"
	Prompt delimiters, "Delimiters of a file name (list)"
	String help = "Special characters\r"
	help+= "%B : basename (filename without extension)\r"
	help+= "%D : directory (path without filename)\r"
	help+= "%E : extention\r"
	help+= "%F : filename (=%B+\".\"+%E)\r"
	help+= "%P : fullpath\r"
	DoPrompt/HELP=help "Open Files",command,dirhint,filetype,extensions,delimiters
	if(!V_Flag)
		ml.command    = command
		ml.dirhint    = dirhint
		ml.filetype   = filetype
		ml.extensions = extensions
		ml.delimiters = delimiters
		ml.load(ml)
	endif
End

// <<NOTE>>
// Special Characters for ml.command and ml.dirhint
// %B : basename (filename without extension)
// %D : directory (path without filename)
// %E : extention
// %F : filename (=%B+"."+%E)
// %P : fullpath

////////////////////////////////////////////////////////////////////////////////
// Menu ////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Menu StringFromList(0,Multiload_Menu)
	RemoveListItem(0,Multiload_Menu)
	Multiload#MenuItem(0),  /Q, MultiLoad#MenuCommand(0)
	Multiload#MenuItem(1),  /Q, MultiLoad#MenuCommand(1)
	Multiload#MenuItem(2),  /Q, MultiLoad#MenuCommand(2)
	Multiload#MenuItem(3),  /Q, MultiLoad#MenuCommand(3)
	Multiload#MenuItem(4),  /Q, MultiLoad#MenuCommand(4)
	Multiload#MenuItem(5),  /Q, MultiLoad#MenuCommand(5)
	Multiload#MenuItem(6),  /Q, MultiLoad#MenuCommand(6)
	Multiload#MenuItem(7),  /Q, MultiLoad#MenuCommand(7)
	Multiload#MenuItem(8),  /Q, MultiLoad#MenuCommand(8)
	Multiload#MenuItem(9),  /Q, MultiLoad#MenuCommand(9)
	Multiload#MenuItem(10), /Q, MultiLoad#MenuCommand(10)
	Multiload#MenuItem(11), /Q, MultiLoad#MenuCommand(11)
	Multiload#MenuItem(12), /Q, MultiLoad#MenuCommand(12)
	Multiload#MenuItem(13), /Q, MultiLoad#MenuCommand(13)
	Multiload#MenuItem(14), /Q, MultiLoad#MenuCommand(14)
	Multiload#MenuItem(15), /Q, MultiLoad#MenuCommand(15)
	Multiload#MenuItem(16), /Q, MultiLoad#MenuCommand(16)
	Multiload#MenuItem(17), /Q, MultiLoad#MenuCommand(17)
	Multiload#MenuItem(18), /Q, MultiLoad#MenuCommand(18)
	Multiload#MenuItem(19), /Q, MultiLoad#MenuCommand(19)
End

static Function/S MenuItem(i)
	Variable i
	String fun = StringFromList(i,FunctionList("Multiload_*",";","")), buf
	SplitString/E="(?m)^//\\s*Menu:\\s*(.*)$" ReplaceString("\r",ProcedureText(fun,-1),"\n"), buf
	if(strlen(buf))
		return "\M0"+buf
	else
		return ReplaceString("_",fun[10,inf]," ")
	endif
End

static Function MenuCommand(i)
	Variable i
	Execute/Z StringFromList(i,FunctionList("Multiload_*",";",""))+"()"
End

////////////////////////////////////////////////////////////////////////////////
// Structure ///////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

STRUCTURE Multiload
String command    // command to load waves
String dirhint    // evaluated as a string for make directory hierarchy
String filetype   // just displayed in 'open file' dialogs
String extensions // list delimited with ;
String delimiters // list delimited with ;
FUNCREF Multiload load
ENDSTRUCTURE

////////////////////////////////////////////////////////////////////////////////
// Implementation //////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function Multiload(ml)
	STRUCT Multiload &ml
	
	// Initialize fileds of ml
	String cmd = ""
	if(strlen(ml.command))
		cmd = ml.command
	endif

	String type = ""
	if(strlen(ml.filetype))
		type = ml.filetype
	endif

	String hint = ""
	if(strlen(ml.dirhint))
		hint = ml.dirhint
	endif
	
	Make/FREE/T/N=0 exts
	if(strlen(ml.extensions))
		InsertPoints 0, ItemsInList(ml.extensions), exts
		exts = StringFromList(p,ml.extensions)
	endif

	Make/FREE/T/N=0 dels
	if(strlen(ml.delimiters))
		InsertPoints 0, ItemsInList(ml.delimiters), dels
		dels = StringFromList(p,ml.delimiters)
	endif

	
	// Get filenames by dialog	
	Open/D/R/MULT=1/F=ExtFlag(exts, type) refnum
	if(strlen(S_FileName) == 0)
		return NaN
	endif
	Make/FREE/T/N=(ItemsInList(S_FileName,"\r")) files = StringFromList(p, S_FileName, "\r")
	
	MultiLoadImplement(files, dels, cmd, hint)
End

static Function MultiLoadImplement(files, dels, cmd, hint)
	WAVE/T files, dels; String cmd, hint
	// Make matrix from filenames and sort it
	Variable loaded, i
	for(loaded = 0, i = 0 ; loaded < DimSize(files, 0) ;i += 1)
		WAVE/T matrix = JoinRows( SortRows( FileNameMatrix(i, files, dels, hint) ) )
		loaded += ItemsInList(note(matrix),"\r")
		
		Variable j,N = DimSize(matrix, 1)
		for(j = 0; j < N; j += 1)
		
			// Make a data folder
			Make/FREE/T/N=(DimSize(matrix, 0)) folders = matrix[p][j]
			String folder = MakeDataFolder(folders)
			
			DFREF here = GetDataFolderDFR()
			SetDataFolder $folder
			
			// Load the file
			String path = StringFromList(j,note(matrix),"\r")
			Execute/Z ExpandExpr(cmd, path)
			print GetErrMessage(V_Flag)	
					
			SetDataFolder here
		endfor
	endfor
End

// Make a folder and load waves 
static Function/S MakeDataFolder(folders)
	WAVE/T folders
	DFREF here = GetDataFolderDFR()
	Variable i,N=DimSize(folders,0)
	for(i=0;i<N;i+=1)
		Execute/Z/Q "NewDataFolder/O/S :"+PossiblyQuoteName(RenameToIgorFolderName(folders[i]))
	endfor
	String path = GetDataFolder(1)
	SetDataFolder here
	return path
End

// Replace characters which are unavailable for Igor Pro folder path
static Function/S RenameToIgorFolderName(name)
	String name
	name=ReplaceString(";" ,name,""); name=ReplaceString(":" ,name,"")
	name=ReplaceString("\"",name,""); name=ReplaceString("'" ,name,"")
	return Truncate(name)
End

// Shorten too long path name
static Function/S Truncate(name)
	String name
	return name[0,30]
End

// Make message in an 'open file' dialog
static Function/S ExtFlag(exts, type)
	WAVE/T exts; String type
	
	if(DimSize(exts,0) == 0)
		return "All Files (*.*):.*;"
	endif
	
	String exts1="", exts2=""
	Variable i,N=DimSize(exts,0)
	for(i = 0; i < N; i += 1)
		String ext = SelectString(StringMatch(exts,".*"),".","")+exts[i]+","
		exts1 += "*"+ext
		exts2 += ext
	endfor
	exts1=RemoveEnding(exts1,",")
	exts2=RemoveEnding(exts2,",")
	
	String msg = SelectString(strlen(type),"",type+" ")
	sprintf msg, "%s(%s):%s;All Files (*.*):.*;", msg, exts1, exts2
	return msg
End

////////////////////////////////////////////////////////////////////////////////
// Functions to sort elements of pathnames as matrix ///////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Joint rows whose items have the same order 
static Function/WAVE JoinRows(matrix)
	WAVE/T matrix
	Variable N0 = DimSize(matrix, 0), N1 = DimSize(matrix, 1)
	Make/FREE/T/N=(0, N1) joined
	
	Variable i
	for(i = 0; i < N0; i += 1)
		Make/FREE/T/N=(N1) ref = matrix[i][p]
		InsertPoints/M=0 DimSize(joined,1), 1, joined
		joined[DimSize(joined, 0) - 1][] = ref[q]

		Variable j
		for(j = i+1; j < N0; j += 1)
			Make/FREE/T/N=(N1) buf = matrix[j][p]
			if( DimSize(Unique(ref), 0) == DimSize(Unique(buf), 0) )
				joined[DimSize(joined, 0) - 1][] += "_"+buf[q]
				i += 1
			endif			
		endfor

	endfor
	
	Note joined note(matrix)
	return joined	
End

// Sort rows by number of unique items
static Function/WAVE SortRows(matrix)
	WAVE/T matrix
	Duplicate/FREE/T matrix sorted
	
	Variable count = 0
	Variable i, Ni = DimSize(matrix,1)
	for(i = 1; i <= Ni; i += 1)

		Variable j, Nj = DimSize(matrix,0)
		for(j = 0; j < Nj; j += 1)
			Make/FREE/T/N=(DimSize(matrix,1)) w=matrix[j][p]
			if(i == DimSize(Unique(w), 0))
				sorted[count][] = w[q]
				count += 1
			endif
		endfor

	endfor

	return sorted
End

// Remove duplicate values
static Function/WAVE Unique(w)
	WAVE/T w
	if(DimSize(w,0))
		Make/FREE/T head = {w[0]}
		Extract/T/FREE w, tail, cmpstr(w[0],w)
		Concatenate/T/NP {Unique(tail)}, head
		return head
	endif
	Make/FREE/T/N=0 f
	return f
End

// Convert filenames into text wave matrix
static Function/WAVE FileNameMatrix(num, files, dels, hint)
	Variable num; WAVE/T files, dels; String hint
	Make/FREE/T/N=0 matrix
	Variable i,N = DimSize(files, 0)
	for(i = 0; i < N; i += 1)
		WAVE/T w = SplitLine(EvalString(ExpandExpr(hint, files[i])), dels)
		if(DimSize(w,0) == num)
			Concatenate/T {w}, matrix
			Note matrix, files[i]
		endif
	endfor
	if(DimSize(matrix, 1) == 0)
		Make/FREE/T/N=(DimSize(matrix,0), 1) buf = matrix
		Note buf, note(matrix)
		return buf 
	else
		return matrix
	endif
End

// Split a string with delimiters
static Function/WAVE SplitLine(line, dels)
	String line; WAVE/T dels
	Variable i,N = DimSize(dels,0)
	for(i = 0; i < N; i += 1)
		line = ReplaceString(dels[i], line, "\r")
	endfor
	Make/FREE/T/N=(ItemsInList(line,"\r")) w = StringFromList(p, line, "\r")
	return w
End

////////////////////////////////////////////////////////////////////////////////
// Functions about pathname manipulation ///////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Evaluate expression as a string 
static Function/S EvalString(expr)
	String expr
	DFREF here = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	try
		Execute/Z "String S_Value="+expr
		SVAR S_Value
		String s = S_Value 
		SetDataFolder here
	catch
		SetDataFolder here	
	endtry
	return s
End

// Expand special characters
static Function/S ExpandExpr(expr, path)
	String path, expr
	expr = ExpandExpr1(expr, "%B", "%%", "\"" + basename(path)  + "\"")
	expr = ExpandExpr1(expr, "%D", "%%", "\"" + dirname(path)   + "\"")
	expr = ExpandExpr1(expr, "%E", "%%", "\"" + extension(path) + "\"")
	expr = ExpandExpr1(expr, "%F", "%%", "\"" + filename(path)  + "\"")
	expr = ExpandExpr1(expr, "%P", "%%", "\"" + path            + "\"")
	expr = ReplaceString("%%",expr,"%")
	return expr
End

// Expand one special character
static Function/S ExpandExpr1(s,expr,esc,repl)
	String s,expr,esc,repl
	String head,body,tail
	SplitString/E="(.*?)("+esc+"|"+expr+")(.*)" s,head,body,tail
	if(strlen(body)==0)
		return s
	endif
	return head + SelectString(GrepString(body,esc), repl, esc) + ExpandExpr1(tail,expr,esc,repl)
End

// extension
static Function/S extension(path)
	String path
	return ParseFilePath(4,path,":",0,0)
End
// filename without extension
static Function/S basename(path)
	String path
	return ParseFilePath(3,path,":",0,0)
End
// filename
static Function/S filename(path)
	String path
	return basename(path)+"."+extension(path)
End
// directory name
static Function/S dirname(path)
	String path
	return RemoveEnding(path,filename(path))
End
