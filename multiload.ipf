#pragma ModuleName=Multiload

Function ml_test()
	STRUCT Multiload ml
	ml.filetype   = "Data Files"
	ml.extensions = ".dat;.txt"
	ml.delimiters = "_; "
	FUNCREF Multiload_Hint ml.hintfunc = $""
	FUNCREF Multiload_Load ml.loadfunc = $""
	ml.load(ml)
End

////////////////////////////////////////
// Structure ///////////////////////////
////////////////////////////////////////
STRUCTURE Multiload
	FUNCREF Multiload_Load loadfunc
	FUNCREF Multiload_Hint hintfunc
	String filetype   // just displayed in 'open file' dialogs
	String extensions // list delimited with ;
	String delimiters // list delimited with ;
	String filenames  // list delimited with CR
	FUNCREF Multiload load
ENDSTRUCTURE

Function Multiload_Load(path)
	String path
	String cmd; sprintf cmd,"LoadWave/A/D/G/Q \"%s\"", path
	Execute/Z cmd
End
Function/S Multiload_Hint(filename)
	String filename
	return filename
End
Function InitializeProperties(ml)
	STRUCT MultiLoad &ml
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
			FUNCREF Multiload_load func = ml.loadfunc
			Load(path[j],words,func)
		endfor
	endfor
End


Function Load(path,words,loadfunc)
	String path; WAVE/T words; FUNCREF Multiload_Load loadfunc
	DFREF here = GetDataFolderDFR()
	Variable i,N=DimSize(words,0)
	for(i=0;i<N;i+=1)
		Execute/Z/Q "NewDataFolder/O/S "+PossiblyQuoteName(RenameToIgorFolderName(words[i]))
	endfor	
	loadfunc(path)
	SetDataFolder here
End
Function/S RenameToIgorFolderName(name)
	String name
	name=ReplaceString(";" ,name,""); name=ReplaceString(":" ,name,"")
	name=ReplaceString("\"",name,""); name=ReplaceString("'" ,name,"")
	return name[0,30]
End 


// Make message in an 'open file' dialog
Function/S ExtensionFlag(ml)
	STRUCT Multiload &ml
	if(ItemsInList(ml.extensions))
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
Function/WAVE JoinRows(matrix)
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
Function/WAVE JoinRows_(accum,matrix)
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
Function/WAVE SortRows(matrix)
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
Function NumberOfUniqueItems(w)
	WAVE/T w
	if(DimSize(w,0))
		Extract/T/FREE w,f,cmpstr(w[0],w)
		return 1+NumberOfUniqueItems(f)
	endif
	return 0
End

// Convert filenames into text wave matrix
// fullpaths are written in the wavenote
Function/WAVE GetWords(line,delimiters)
	String line, delimiters
	Variable i,N=ItemsInList(delimiters)
	for(i=0;i<N;i+=1)
		line = ReplaceString(StringFromList(i,delimiters),line,"\r")
	endfor
	Make/FREE/T/N=(ItemsInList(line,"\r")) w=StringFromList(p,line,"\r")
	return w
End
Function NumberOfWords(line,delimiters)
	String line, delimiters
	return DimSize(GetWords(line,delimiters),0)
End
Function MaximumNumberOfWords(ml)
	STRUCT MultiLoad &ml
	Make/FREE/T/N=(ItemsInList(ml.filenames,"\r")) path=StringFromList(p,ml.filenames,"\r")
	Make/FREE/N=(DimSize(path,0)) num=NumberOfWords(ml.hintfunc(basename(path)),ml.delimiters)
	return WaveMax(num)
End
Function/WAVE GetMatrixByNumberOfWords(ml,num)
	STRUCT MultiLoad &ml; Variable num
	Make/FREE/T/N=(ItemsInList(ml.filenames,"\r")) path=StringFromList(p,ml.filenames,"\r")
	Extract/T/FREE path,path,num==NumberOfWords(ml.hintfunc(basename(path)),ml.delimiters)
	Variable i,j,N=DimSize(path,0); Make/FREE/T/N=(N,num) buf
	for(i=0;i<N;i+=1)
		Note buf,path[i]
		WAVE/T words = GetWords(ml.hintfunc(basename(path[i])),ml.delimiters)
		for(j=0;j<num;j+=1)
			buf[i][j] = words[j]
		endfor
	endfor
	return buf
End
Function/S basename(path)
	String path
	return ParseFilePath(3,path,":",0,0)
End