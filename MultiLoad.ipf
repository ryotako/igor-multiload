#pragma modulename=debug

//ファイル名からフォルダ構造を作らず、UniqueNameで1ファイル1フォルダで読む機能も選べるようにすること

Function Dialog_OpenFiles()
	String ext; Prompt ext,"拡張子（未入力の場合、すべての拡張子）"
	String sep; Prompt sep,"ファイル名の区切り文字"
	DoPrompt/HELP="" "Open Files",ext,sep; DoAbort(V_Flag); OpenFiles({ext},{sep})
End


//拡張子と区切り文字を複数指定できますが、「拡張子と区切り文字を除けば同名」であるファイルが選ばれていると
//一つのフォルダに複数のファイルからウェーブがロードされることになります。
//igorは31文字を超えるデータフォルダ名を認めないため、区切り文字で分割したあとの要素が31字を超える場合、
//フォルダ作成に際しては複数のフォルダが同名であると解釈され、同様の問題が生じ得ます

Function OpenFiles(exts,seps [r,i])
	WAVE/T exts,seps
	FUNCREF ProtoTypeForOpenFilesRemaner r //フォルダ作成のヒントとして使うファイル名に干渉する
	FUNCREF ProtoTypeForOpenFilesInitial i //データをロードしたフォルダでウェーブ名変更等を行う
	Open/D/R/MULT=1/F=ExtensionFlag(exts) refNum; DoAbort(strlen(S_FileName)==0)
	STRUCT FILES fs; fs.new(fs,S_FileName)
	do
		WAVE/T names=fs.pop(fs,seps); Make/FREE/T/N=(numpnts(names)) alias=RemoveExtensions( r(names),exts)
		Load(Shorten(SortByKinds(Separate2Matrix(alias,seps))),names,fs.path, i)
	while(numpnts(fs.names))
End
Function/S ProtoTypeForOpenFilesRemaner(s)
	String s
	return s
End
Function/D ProtoTypeForOpenFilesInitial()
End

//強制終了
static Function DoAbort(bool)
	Variable bool
	if(bool)
		Abort
	endif
End

//ファイルの拡張子に関する関数
static Function/S ExtensionFlag(exts)
	WAVE/T exts
	Variable i; String buf=""
	for(i=0;i<numpnts(exts);i+=1)
		buf=buf+SelectString(i,"",",")+Dotted(exts[i])
	endfor
	return SelectString(strlen(buf),"All Files (*.*):.*;","Data Files (*"+buf+"):"+buf+";")
End
static Function/S RemoveExtensions(s,exts)
	String s; WAVE/T exts
	Variable i
	for(i=0;i<numpnts(exts);i+=1)
		String buf=RemoveEnding(s,Dotted(exts[i]))
		if(strlen(buf)!=strlen(s))
			return buf
		endif
	endfor
	return s
End
static Function/S Dotted(s)
	String s
	return SelectString(cmpstr(s[0],".")&&strlen(s),s,"."+s)
End

//実際にウェーブをロードする関数
static Function Load(matrix,names,path,func)
	WAVE/T matrix,names; String path; FUNCREF ProtoTypeForOpenFilesInitial func
	STRUCT tMatrix m; m.clone(m,matrix)
	DFREF here=GetDataFolderDFR(); Variable i,j
	for(i=0;i<numpnts(names);i+=1)
		WAVE/T row=m.rGet(m,i)
		for(j=0;j<numpnts(row);j+=1)
			Execute "NewDataFolder/O/S "+PossiblyQuoteName(RenameForIgor(row[j],m.cGet(m,j)))
		endfor
	LoadWave/A/D/G/Q (path+names[i]); String/G $"S_fileName"=path+names[i]; func()
	SetDataFolder here
	endfor
End
static Function/S RenameForIgor(name,col)
	String name; WAVE/T col
	name=ReplaceString(";" ,name,""); name=ReplaceString(":" ,name,"")
	name=ReplaceString("\"",name,""); name=ReplaceString("'" ,name,"")
	return name[0,30]
End 

//文字列の行列を変形する関数
static Function/WAVE Shorten(matrix)
	WAVE/T matrix
	STRUCT tMatrix tm; tm.clone(tm,matrix); Variable i,j,flag
	for(i=0;i<tm.cNum(tm)-1;i+=!flag)
		for(j=i+1;j<tm.cNum(tm);j+=!flag)
			WAVE/T prev=tm.cGet(tm,i); WAVE/T next=tm.cGet(tm,j)
			WAVE/T sums=tm.cGet(tm,i); sums=prev+"_"+next
			Make/FREE/D/N=(numpnts(sums)) count=strlen(sums)
			flag=(CountKinds(sums)==min(CountKinds(next),CountKinds(prev)) && WaveMax(count)<27)
			if(flag)
				tm.cInsert(tm,i,sums); tm.cDelete(tm,j+1); tm.cDelete(tm,i+1)
			endif
		endfor
	endfor
	return tm.matrix
End
static Function/WAVE SortByKinds(matrix)
	WAVE/T matrix
	STRUCT tMatrix tm; tm.clone(tm,matrix)
	Variable i,j,num=tm.cNum(tm)
	for(i=0;i<num-1;i+=1)
		for(j=0;j<num;j+=1)
			WAVE/T prev=tm.cGet(tm,j); WAVE/T next=tm.cGet(tm,j+1)
			if(CountKinds(prev)>CountKinds(next))
				tm.cInsert(tm,j,tm.cDelete(tm,j+1))
			endif
		endfor	
	endfor
	return tm.matrix	
End
static Function CountKinds(xs)
	WAVE/T xs
	Duplicate/FREE/T xs buf; Variable i,size=numpnts(buf)
	for(i=size-1;i>=0;i-=1)
		if(cmpstr(buf[i],buf[0])==0)
			DeletePoints i,1,buf
		endif
	endfor
	return (size>0)+(numpnts(buf) ? CountKinds(buf) : 0)
End

//テキストウェーブを行列に変換
static Function/WAVE Separate2Matrix(names,separators)
	WAVE/T names,separators
	STRUCT tMatrix tm; tm.new(tm,0,0); Variable i
	for(i=0;i<numpnts(names);i+=1)
		String name = names[i]
		tm.rInsert(tm,i,SeparateByWords(name,separators))
	endfor
	return tm.matrix
End
//文字列をウェーブに変換
static Function/WAVE SeparateByWords(s,words)
	String s; WAVE/S words
	Make/FREE/T/N=0 result
	if(strlen(s))
		Variable n=abs(SearchWords(s,words)); Make/FREE/T/N=1 f=s[0,n-1]
		Concatenate/NP/T {f,SeparateByWords(s[n+1,inf],words)},result
	endif
	return result
End
static Function SearchWords(s,words)
	String s; WAVE/T words
	Make/FREE/D/N=(numpnts(words)) f=abs(cmpstr(s[0],words[p]))
	return WaveMin(f)==0 ? 0 : (strlen(s) ? 1+SearchWords(s[1,inf],words) : -inf)
End

//構造体1: ファイルパスと名前の管理
//セパレータで分けられた要素数が同じになるものをpopで順に取り出す
static STRUCTURE Files
	FUNCREF FilesForOpenFiles_New new
	FUNCREF FilesForOpenFiles_Pop pop
	String path
	WAVE/T names
ENDSTRUCTURE
Function FilesForOpenFiles_New(self,S_FileName)
	STRUCT Files &self; String S_FileName
	String fst=StringFromList(0,S_FileName,"\r"); self.path =RemoveListItem(ItemsInList(fst,":")-1,fst,":")
	Make/FREE/T/N=(ItemsInList( S_FileName,"\r")) self.names=StringFromList(p,S_FileName,"\r")
	self.names=StringFromList(ItemsInList(self.names,":")-1,self.names,":")
End
Function/WAVE FilesForOpenFiles_Pop(self,separators)
	STRUCT Files &self; WAVE/T separators
	Make/FREE/D/N=(numpnts(self.names)) nums=numpnts(SeparateByWords(self.names[p],separators))
	Make/FREE/T/N=(numpnts(self.names)) buf; Variable i,j=numpnts(self.names)
	for(i=numpnts(self.names);i>0;i-=1)
		if(nums[i-1]==WaveMin(nums))
			buf[j-1]=self.names[i-1]; j-=1; DeletePoints i-1,1,self.names
		endif
	endfor
	DeletePoints 0,j,buf; return buf
End

//構造体2: 文字列を行列形式で管理
STRUCTURE tMatrix
	FUNCREF tMatrix_New			new
	FUNCREF tMatrix_Clone		clone
	FUNCREF tMatrix_RowInsert	rInsert
	FUNCREF tMatrix_ColInsert	cInsert
	FUNCREF tMatrix_RowDelete	rDelete
	FUNCREF tMatrix_ColDelete	cDelete
	FUNCREF tMatrix_RowGet		rGet
	FUNCREF tMatrix_ColGet		cGet
	FUNCREF tMatrix_RowNumber	rNum
	FUNCREF tMatrix_ColNumber	cNum
	WAVE/T  matrix
ENDSTRUCTURE

Function tMatrix_New(self,row,col)
	STRUCT tMatrix &self; Variable row,col
	Make/FREE/T/N=(row,col) self.matrix
End
Function tMatrix_Clone(self,matrix)
	STRUCT tMatrix &self; WAVE/T matrix
	Duplicate/FREE/T matrix self.matrix
End

Function tMatrix_RowInsert(self,n,row)
	STRUCT tMatrix &self; Variable n; WAVE/T row
	n=min(DimSize(self.matrix,0),max(0,n))
	if(numpnts(self.matrix))
		WAVE/T m=self.matrix; InsertPoints/M=0 n,1,m
		m=SelectString(p==n,m[p][q],row[q])
	else
		Make/FREE/T/N=(1,numpnts(row)) self.matrix=row[q]
	endif
End
Function tMatrix_ColInsert(self,n,col)
	STRUCT tMatrix &self; Variable n; WAVE/T col
	n=min(DimSize(self.matrix,1),max(0,n))
	if(numpnts(self.matrix))
		WAVE/T m=self.matrix; InsertPoints/M=1 n,1,m
		m=SelectString(q==n,m[p][q],col[p])
	else
		Make/FREE/T/N=(1,numpnts(row)) self.matrix=col[p]
	endif
End

Function/WAVE tMatrix_RowDelete(self,n)
	STRUCT tMatrix &self; Variable n
	n=min(DimSize(self.matrix,0)-1,max(0,n))
	Make/FREE/T/N=(DimSize(self.matrix,1)) f=self.matrix[n][p]
	DeletePoints/M=0 n,1,self.matrix; return f	
End
Function/WAVE tMatrix_ColDelete(self,n)
	STRUCT tMatrix &self; Variable n
	n=min(DimSize(self.matrix,1)-1,max(0,n))
	Make/FREE/T/N=(DimSize(self.matrix,0)) f=self.matrix[p][n]
	DeletePoints/M=1 n,1,self.matrix; return f	
End

Function/WAVE tMatrix_RowGet(self,n)
	STRUCT tMatrix &self;Variable n
	n=min(DimSize(self.matrix,0)-1,max(0,n))
	Make/FREE/T/N=(DimSize(self.matrix,1)) f=self.matrix[n][p]; return f
End
Function/WAVE tMatrix_ColGet(self,n)
	STRUCT tMatrix &self;Variable n
	n=min(DimSize(self.matrix,1)-1,max(0,n))
	Make/FREE/T/N=(DimSize(self.matrix,0)) f=self.matrix[p][n]; return f	
End

Function tMatrix_RowNumber(self)
	STRUCT tMatrix &self
	return DimSize(self.matrix,0)
End
Function tMatrix_ColNumber(self)
	STRUCT tMatrix &self
	return DimSize(self.matrix,1)
End