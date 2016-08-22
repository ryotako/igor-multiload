#pragma ModuleName=Multiload
strconstant Multiload_Menu="Multiload"

////////////////////////////////////////
// Setting /////////////////////////////
////////////////////////////////////////

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


////////////////////////////////////////
// Menu ////////////////////////////////
////////////////////////////////////////
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


// Special Characters for ml.command and ml.dirhint
// %B : basename (filename without extension)
// %D : directory (path without filename)
// %E : extention
// %F : filename (=%B+"."+%E)
// %P : fullpath


////////////////////////////////////////
// Structure ///////////////////////////
////////////////////////////////////////
STRUCTURE Multiload
	String command    // command to load waves
	String dirhint    // evaluated as a string for make directory hierarchy
	String filetype   // just displayed in 'open file' dialogs
	String extensions // list delimited with ;
	String delimiters // list delimited with ;
	String filenames  // list delimited with CR
	FUNCREF Multiload load
ENDSTRUCTURE

static Function InitializeProperties(ml)
	STRUCT MultiLoad &ml
	if(NumType(strlen(ml.command)))
		ml.command=""
	endif
	if(NumType(strlen(ml.filetype)))
		ml.filetype=""
	endif
	if(NumType(strlen(ml.extensions)))
		ml.extensions=""
	endif
	if(NumType(strlen(ml.delimiters)))
		ml.delimiters=""
	endif	
	if(NumType(strlen(ml.filenames)))
		ml.filenames=""
	endif	
End

////////////////////////////////////////
// Implement ///////////////////////////
////////////////////////////////////////
Function Multiload(ml)
	STRUCT Multiload &ml
	InitializeProperties(ml)

	// Get filenames by dialog	
	Open/D/R/MULT=1/F=ExtensionFlag(ml) refnum
	if(strlen(S_FileName)==0)
		return NaN
	endif
	ml.filenames = S_FileName
	
	Variable i,j,N=MaximumNumberOfWords(ml)
	for(i=1;i<=N;i+=1) // Pick up names which has same number of items

		WAVE/T buf = GetMatrixByNumberOfWords(ml,i)
		WAVE/T matrix = JoinRows( SortRows( buf ) )
		Make/FREE/T/N=(ItemsInList(note(buf),"\r")) path = StringFromList(p,note(buf),"\r")
		
		for(j=0;j<DimSize(matrix,0);j+=1) // Load each file
			Make/FREE/T/N=(DimSize(matrix,1)) words = matrix[j][p]
			MakeFolderAndLoad(path[j],words,ml.command)
		endfor
	endfor
End

// Make a folder and load waves 
static Function MakeFolderAndLoad(path,words,command)
	String path,command; WAVE/T words
	DFREF here = GetDataFolderDFR()
	Variable i,N=DimSize(words,0)
	for(i=0;i<N;i+=1)
		Execute/Z/Q "NewDataFolder/O/S "+PossiblyQuoteName(RenameToIgorFolderName(words[i]))
	endfor
	Load(path,command)
	SetDataFolder here
End
static Function Load(path,command)
	String path,command
	command = ExpandExpr(command,"%B","%%","\""+basename(path) +"\"")
	command = ExpandExpr(command,"%D","%%","\""+dirname(path)  +"\"")
	command = ExpandExpr(command,"%E","%%","\""+extension(path)+"\"")
	command = ExpandExpr(command,"%F","%%","\""+filename(path) +"\"")
	command = ExpandExpr(command,"%P","%%","\""+path           +"\"")
	command = ReplaceString("%%",command,"%")
	Execute/Z command
//	print GetErrMessage(V_Flag)
End
static Function/S ExpandExpr(s,expr,esc,repl)
	String s,expr,esc,repl
	String head,body,tail
	SplitString/E="(.*?)("+esc+"|"+expr+")(.*)" s,head,body,tail
	if(strlen(body)==0)
		return s
	elseif(GrepString(body,esc))
		return head+esc +ExpandExpr(tail,expr,esc,repl)
	else
		return head+repl+ExpandExpr(tail,expr,esc,repl)
	endif
End
static Function/S RenameToIgorFolderName(name)
	String name
	name=ReplaceString(";" ,name,""); name=ReplaceString(":" ,name,"")
	name=ReplaceString("\"",name,""); name=ReplaceString("'" ,name,"")
	return Truncate(name)
End
static Function/S Truncate(name)
	String name
	return name[0,30]
End

// Make message in an 'open file' dialog
static Function/S ExtensionFlag(ml)
	STRUCT Multiload &ml
	if(ItemsInList(ml.extensions)==0)
		return "All Files (*.*):.*;"
	endif
	Variable i,N=ItemsInList(ml.extensions); String exts1="",exts2=""
	for(i=0;i<N;i+=1)
		String ext = StringFromList(i,ml.extensions)
		exts1 += "*"+SelectString(cmpstr(ext[0],"."),"",".")+ext+","
		exts2 += SelectString(cmpstr(ext[0],"."),"",".")+ext+","
	endfor
	exts1=RemoveEnding(exts1,",")
	exts2=RemoveEnding(exts2,",")
	String msg
	if(strlen(ml.filetype))
		sprintf msg, "%s (%s):%s;All Files (*.*):.*;", ml.filetype, exts1, exts2
	else
		sprintf msg, "(%s):%s;All Files (*.*):.*;", exts1, exts2
	endif
	return msg
End

// Joint rows whose items have the same order 
static Function/WAVE JoinRows(matrix)
	WAVE/T matrix
	Make/FREE/T/N=0 empty
	WAVE/T buf=JoinRows_(empty,matrix)
	if(DimSize(buf,1)==0)
		Make/FREE/T/N=(DimSize(buf,0),1) buf2=buf[p]
		return buf2
	else
		return buf
	endif
End
static Function/WAVE JoinRows_(accum,matrix)
	WAVE/T accum,matrix
	Duplicate/FREE/T accum,buf
	Duplicate/FREE/T/R=[0,inf][0,  0] matrix,head
	Duplicate/FREE/T/R=[0,inf][1,inf] matrix,tail
	Variable i,N=numpnts(buf) ? max(1,DimSize(buf,1)) : 0 ,matched=0
	for(i=0;i<N;i+=1)
		Make/FREE/T/N=(DimSize(buf,0)) w1=buf[p][i]
		Make/FREE/T/N=(DimSize(buf,0)) w2=buf[p][i]+"_"+head[p]
		Make/FREE/N=(DimSize(buf,0)) len=strlen(w2)	
		if(NumberOfUniqueItems(w1)==NumberOfUniqueItems(w2) && WaveMax(len)<32 )
			matched=1
			buf[][i]=w2
			break
		endif
	endfor
	if(matched==0)
		Concatenate/T {head},buf
	endif
	if(DimSize(matrix,1)<2)
		return buf
	endif
	return JoinRows_(buf,tail)
End

// Sort rows by number of unique items
static Function/WAVE SortRows(matrix)
	WAVE/T matrix
	Make/FREE/T/N=0 buf
	Variable i,j
	for(i=1;i<=DimSize(matrix,0);i+=1)
		for(j=0;j<DimSize(matrix,1);j+=1)
			Make/FREE/T/N=(DimSize(matrix,0)) w=matrix[p][j]
			if(i==NumberOfUniqueItems(w))
				Concatenate/T {w},buf
			endif
		endfor
	endfor
	return buf
End
static Function NumberOfUniqueItems(w)
	WAVE/T w
	if(DimSize(w,0))
		Extract/T/FREE w,f,cmpstr(w[0],w)
		return 1+NumberOfUniqueItems(f)
	endif
	return 0
End

// Convert filenames into text wave matrix
// (fullpaths are written in the wavenote)
static Function/WAVE GetWords(line,delimiters)
	String line, delimiters
	Variable i,N=ItemsInList(delimiters)
	for(i=0;i<N;i+=1)
		line = ReplaceString(StringFromList(i,delimiters),line,"\r")
	endfor
	Make/FREE/T/N=(ItemsInList(line,"\r")) w=StringFromList(p,line,"\r")
	return w
End
static Function NumberOfWords(line,delimiters)
	String line, delimiters
	return DimSize(GetWords(line,delimiters),0)
End
static Function MaximumNumberOfWords(ml)
	STRUCT MultiLoad &ml
	Make/FREE/T/N=(ItemsInList(ml.filenames,"\r")) path=StringFromList(p,ml.filenames,"\r")
	Make/FREE/N=(DimSize(path,0)) num=NumberOfWords(Hint(path,ml.dirhint),ml.delimiters)
	return WaveMax(num)
End
static Function/S Hint(path,command)
	String path,command
	command = ExpandExpr(command,"%B","%%","\""+basename(path) +"\"")
	command = ExpandExpr(command,"%D","%%","\""+dirname(path)  +"\"")
	command = ExpandExpr(command,"%E","%%","\""+extension(path)+"\"")
	command = ExpandExpr(command,"%F","%%","\""+filename(path) +"\"")
	command = ExpandExpr(command,"%P","%%","\""+path           +"\"")
	command = ReplaceString("%%",command,"%")
	DFREF here = GetDataFolderDFR()
	SetDataFolder NewFreeDataFolder()
	Execute/Z "String S_Hint="+command
	SVAR S_Hint; String hint=S_Hint 
	SetDataFolder here
	return hint
End
static Function/WAVE GetMatrixByNumberOfWords(ml,num)
	STRUCT MultiLoad &ml; Variable num
	Make/FREE/T/N=(ItemsInList(ml.filenames,"\r")) path=StringFromList(p,ml.filenames,"\r")
	Extract/T/FREE path,path,num==NumberOfWords(Hint(path,ml.dirhint),ml.delimiters)
	Variable i,j,N=DimSize(path,0); Make/FREE/T/N=(N,num) buf
	for(i=0;i<N;i+=1)
		Note buf,path[i]
		WAVE/T words = GetWords(Hint(path[i],ml.dirhint),ml.delimiters)
		for(j=0;j<num;j+=1)
			buf[i][j] = words[j]
		endfor
	endfor
	return buf
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
