
function manifest()
    myManifest = {
        name          = "UCore4Vocaloid",
         comment       = "让Vocaloid可以调用UTAU音源",
        author        = "大泽456",
        pluginID      = "{BC53A9FF-3BC4-4AdF-eaf6-AF0GGB34AFCC}",
        pluginVersion = "0.0.1.0",
        apiVersion    = "3.0.1.0"
    }
    
    return myManifest
end


--
-- 定数定義.
--

-- リターンコード.
VS_TRUE       = 1	-- JobプラグインAPIの真偽値の真.
VS_FALSE      = 0	-- JobプラグインAPIの真偽値の偽.
STATUS_NORMAL = 0	-- 正常終了.
STATUS_ABEND  = 1	-- エラー終了.

-- ぼかりす本体から出力されたテンポラリファイルの行の種別.
LINETYPE_NULL    = 0	-- 空行またはコメント行.
LINETYPE_SECTION = 1	-- セクション行.
LINETYPE_KEY_VAL = 2	-- キー = 値 行.


--
-- グローバル変数.
--

g_PI=3.1415926
g_iniClearArea = "YWL_CLEARAREA"
g_iniNewCtrl = "YW_NewCtrl"
g_inClearAreaList  = {}
g_inClearAreaCount = 0
g_inNewCtrlList  = {}
g_inNewCtrlCount = 0

-- ノートリスト.
g_inNoteList = {}		-- ぼかりす本体へ入力するノートリスト.
g_inNoteListSize = 0	-- ぼかりす本体へ入力するノートリスト中のノートの個数.
PORList={}
PORSize=0
PORHandle=0
DYNList={}
DYNSize=0
DYNHandle=0

-- 実行時に渡されたパラメータ.
g_beginPosTick = 0		-- 選択範囲の始点時刻（ローカルTick）.
g_endPosTick   = 0		-- 選択範囲の終点時刻（ローカルTick）.
g_songPosTick  = 0		-- カレントソングポジション時刻（ローカルTick）.

-- 実行時に渡された実行環境パラメータ.
g_scriptDir  = ""		-- Luaスクリプトが配置されているディレクトリパス（末尾にデリミタ "\" を含む）.
g_scriptName = ""		-- Luaスクリプトのファイル名.
g_tempDir    = ""		-- Luaプラグインが利用可能なテンポラリディレクトリパス（末尾にデリミタ "\" を含む）.

-- プラグインの実行環境.
g_vocaLisPath     = ".\\UtauCore\\"
g_vocaLisExe      = "UCore.exe"	-- ぼかりす本体のEXEモジュール名.
g_tempInFileName  = "TempIn.ust"			-- ぼかりす本体へ入力するテンポラリファイル名.
g_myTempDir       = ""						-- ぼかりすプラグイン専用のテンポラリディレクトリパス.

--
-- \fn		main(processParam, envParam)
-- \brief	VOCALOID3 Jobプラグインのエントリポイント.
-- \param	processParam	実行条件パラメータテーブル.
-- \param	envParam		実行環境パラメータテーブル.
-- \return 	正常終了のとき STATUS_NORMAL, エラー終了のとき STATUS_ABEND.
--
-- VOCALOID3側から呼び出されます.
-- 当該Jobプラグインのエントリポイント関数となります.
-- 正常に処理が完了したときは 0,エラーによって処理が中止されたときは 1 を返します.
--
function main(processParam, envParam)
	-- ローカル変数宣言.
	local retCode	-- 関数のリターンコード.
	local osCmd		-- 外部EXEコマンド文字列.
	local message	-- エラーメッセージ等.

	-- 実行時に渡されたパラメータを取得する.
	g_beginPosTick = processParam.beginPosTick
	g_endPosTick   = processParam.endPosTick
	g_songPosTick  = processParam.songPosTick

	-- 実行時に渡された実行環境パラメータを取得する.
	g_scriptDir  = envParam.scriptDir
	g_scriptName = envParam.scriptName
	g_tempDir    = envParam.tempDir
	-- プラグイン専用のテンポラリディレクトリパス.
	

	--
	-- このJobプラグインのメインルーチンを実行する.
	--
	retCode = mainProc(processParam)

	-- 正常終了.
	return retCode
end


--
-- \fn		mainProc()
-- \brief	このJobプラグインのメインルーチン.
-- \return 	正常終了のとき STATUS_NORMAL, エラー終了のとき STATUS_ABEND.
--
function mainProc(processParam)
	-- ローカル変数宣言.
	local retCode			-- 関数のリターンコード.
	local status			-- 外部EXEコマンドのリターンコード.
	local osCmd				-- 外部EXEコマンド文字列.
	local message			-- エラーメッセージ等.
	local tempInFilePath	-- ぼかりす本体へ入力するテンポラリファイルのフルパス.
	local tempOutFilePath	-- ぼかりす本体から出力されるテンポラリファイルのフルパス.

	-- VOCALOID3側からMusicalパートデータを取得する.
	retCode = getMusicalPartFromHost()
	if (retCode ~= STATUS_NORMAL) then
		-- エラーのため処理を中止する.
		return STATUS_ABEND
	end

	-- ぼかりす本体へ入力するテンポラリファイルへデータを書き出す.
	retCode = writeToVocaLisInFile(processParam)
	if (retCode ~= STATUS_NORMAL) then
		-- エラーのため処理を中止する.
		return STATUS_ABEND
	end

	-- ぼかりす本体を起動する.
	osCmd = "\"" .. g_vocaLisPath .. g_vocaLisExe .. "\" \"" .. g_tempInFileName .."\""

	status = os.execute(osCmd)
	if (status ~= 0 and status ~= 259) then
	 	-- 強制終了時は処理を中止.
	 	return STATUS_NORMAL
	end
	--
	
	-- 正常終了.
	return STATUS_NORMAL
end


--
-- \fn		getMusicalPartFromHost()
-- \brief	VOCALOID3側からMusicalパートデータを取得する.
-- \return 	正常終了のとき STATUS_NORMAL, エラー終了のとき STATUS_ABEND.
--
function getMusicalPartFromHost()
	-- ローカル変数宣言.
	local retCode		-- VOCALOID3 JobプラグインAPIからのリターンコード.
	local noteEx		-- Noteデータ.
	local control		-- コントロールイベント.
	local controlType	-- コントロールイベントの種別ID.
	local idx			-- リストへのインデックス.

	-- ノートを取得してノートイベント配列へ格納する.
	VSSeekToBeginNote()
	idx = 1
	retCode, noteEx = VSGetNextNoteEx()
	while (retCode == 1) do
		g_inNoteList[idx] = noteEx
		retCode, noteEx = VSGetNextNoteEx()
		idx = idx + 1
	end
	
	-- 読み込んだノートの総数.
	g_inNoteListSize = table.getn(g_inNoteList)


		retCode = VSSeekToBeginControl("POR")
		idx = 1
		retCode, control = VSGetNextControl("POR")
		while (retCode == 1) do
			PORHandle = 1
			PORList[idx] = control
			retCode, control = VSGetNextControl("POR")
			idx = idx + 1
		end
	PORSize=table.getn(PORList)

		retCode = VSSeekToBeginControl("DYN")
		idx = 1
		retCode, control = VSGetNextControl("DYN")
		while (retCode == 1) do
			DYNHandle = 1
			DYNList[idx] = control
			retCode, control = VSGetNextControl("DYN")
			idx = idx + 1
		end
	DYNSize=table.getn(DYNList)  --$volume=1,50,1,50,30,100,60,149,75,21,100,50

	return STATUS_NORMAL
end

function getPOR(posTick)
	local Ret = 64
	if (PORSize==0) then
		return 64
	else
		if(PORHandle>0 and PORHandle<=PORSize) then
		
			local control		-- コントロールイベント.
			control=PORList[PORHandle]			
			local CurPos=control.posTick
			while(CurPos<posTick and PORHandle<PORSize) do
			
				if (PORList[PORHandle+1].posTick<posTick) then
					PORHandle=PORHandle+1
					local CurPos=PORList[PORHandle].posTick
				else
					break
				end
			end
			local CurPos=PORList[PORHandle].posTick
			while(CurPos>posTick and PORHandle>1) do
				
				if (PORList[PORHandle-1].posTick>posTick) then
					PORHandle=PORHandle-1
					local CurPos=PORList[PORHandle].posTick
				else
					break
				end
			end
			if(PORList[1].posTick>posTick) then
				Ret=64	

			else
				--VSMessageBox(PORList[PORHandle].value,0)
				-- return PORList[PORHandle].value;
				Ret=PORList[PORHandle].value
			end
			-- return PORList[PORHandle].value;
		end
	end
	return Ret
end


function CalcAvgCtrl(CtrlName)
	
	local startP=g_inNoteList[1].posTick+1
	local endP=g_inNoteList[g_inNoteListSize-1].posTick-1
	local dur=endP-startP
	local Peek=math.ceil(dur/4)
	local P={}
	local V={}
	local D={}
	P0=startP
	P1=P0+Peek
	P2=P1+Peek
	P3=P2+Peek
	retCode, V0=VSGetControlAt(CtrlName,P0)
	retCode, V1=VSGetControlAt(CtrlName,P1)
	retCode, V2=VSGetControlAt(CtrlName,P2)
	retCode, V3=VSGetControlAt(CtrlName,P3)
	if (V0==V2 and V1==V2 and V2==V3) then
		return V0
	else
		if(V0==V1 and V1==V2)then
			return V0
		else if(V3==V1 and V1==V2)then
			return V1
		     else 
			if(V0==V1 and V1==V3)then
				return V1
			else
				if(V0==V2 and V2==V3)then
					return V2
				else

	if(V0==V1)then
		return V0
	else
	if(V0==V2)then
		return V0
	else
	if(V0==V3)then
		return V0
	else
	if(V1==V2)then
		return V1
	else
	if(V1==V3)then
		return V1
	else
	if(V2==V3)then
		return V2
	end
	end
	end
	end
	end
	end

		
				end
			end
		     end
		end
	end
end


function vibYValue(idx,posTick)
	local VL=g_inNoteList[idx].vibratoLength
	local VT=g_inNoteList[idx].vibratoType
	if (VT==0) then
		return 0
	else
		local VR=g_inNoteList[idx].durTick*(1-(VL/100))
		local VSR=g_inNoteList[idx].posTick + VR
		local Xidx=posTick-VSR
		local MaxT=30
		local BT=Xidx*MaxT/(g_inNoteList[idx].durTick*((VL/100)))
		if (Xidx>1) then
			return BT * math.sin(Xidx*(g_PI/128))
		else
			return 0
		end
	end
end
--
-- \fn		writeToVocaLisInFile()
-- \brief	ぼかりす本体へ入力するテンポラリファイルへデータを書き出す.
-- \return 	正常終了のとき STATUS_NORMAL, エラー終了のとき STATUS_ABEND.
--
function writeToVocaLisInFile(processParam)



	local beginPosTick = processParam.beginPosTick
	local endPosTick   = processParam.endPosTick
	-- ローカル変数宣言.
	local retCode			-- VOCALOID3 JobプラグインAPIからのリターンコード.
	local message			-- エラーメッセージ等.
	local tempInFilePath	-- ぼかりす本体へ入力するテンポラリファイルのフルパス.
	local tempInFile		-- ぼかりす本体へ入力するテンポラリファイルハンドル.
	local controlValPIT = 0	
	local controlValPBS = 0
	local controlValTEMPO = 0

	local idx				-- リストへのインデックス.

	-- ぼかりす本体へ入力するテンポラリファイルのオープン.
	tempInFilePath = g_vocaLisPath .. g_tempInFileName
	tempInFile, message = io.open(tempInFilePath, "w")
	if (tempInFile == nil) then
		-- テンポラリファイルを作成できない.
		return STATUS_ABEND
	end


	local g_musicalPart = {}
	retCode, g_musicalPart = VSGetMusicalPart()
	if (retCode ~= VS_TRUE) then
		-- エラーのため処理を中止する.
		return STATUS_ABEND
	end

	local tempot
	local tempo				-- テンポデータ.
	VSSeekToBeginTempo()
	retCode, tempo = VSGetNextTempo()
	
	while (retCode == VS_TRUE and tempo.posTick < g_musicalPart.posTick) do --  
		retCode, tempot = VSGetNextTempo()
		if (tempot.tempo > 20 and tempot.posTick < g_musicalPart.posTick) then
			tempo=tempot
		end
	end


	tempInFile:write("[#VERSION]\n")
	tempInFile:write("UST Version1.2\n")
	tempInFile:write("Charset=UTF-8\n\n")	


	tempInFile:write("[#SETTING]\n")
	tempInFile:write("Tempo="..(tempo.tempo).."\n")	
	tempInFile:write("Tracks=1\n")	
	tempInFile:write("ProjectName="..VSGetSequenceName().."\n")	
	tempInFile:write("VoiceDir=XLRR_UTAU\n")	
	tempInFile:write("Tool1=wavtool2.exe\n")	
	tempInFile:write("Tool2=resampler.exe\n")
	tempInFile:write("Mode2=False\n")	
	
	-- ノートイベントの出力.
	local lastPos = 0
	local curIdx=0
	local isFirst = 1
	local lastisR = 0
	local lastNote = 0
	local lastNoteKey = 0
	local lastPointKey = 0
	local MainNoteNum = 60
	local oldlastPos = 0
	local DefBRE=0
	local DefGEN=64
	local DefCLE=0
	local DefBRI=64
	if (g_inNoteListSize > 0) then
		local GFlags=""
		DefBRE = CalcAvgCtrl("BRE")
		if(DefBRE~=0)then
			GFlags="B"..DefBRE
		end
		DefBRI = CalcAvgCtrl("BRI")
		DefCLE = CalcAvgCtrl("CLE")
		DefGEN = CalcAvgCtrl("GEN")
		if(DefGEN~=64)then
			local tp=DefGEN-64
			GFlags=GFlags.."g"..((tp))
		end	
		tempInFile:write("Flags="..GFlags.."\n\n")	
		for idx = 1, g_inNoteListSize do
		if ( 1==1 ) then  -- (beginPosTick<=g_inNoteList[idx].posTick) and (g_inNoteList[idx].posTick+g_inNoteList[idx].durTick<=endPosTick)
			if ( g_inNoteList[idx].posTick > lastPos +1 ) then
				tempInFile:write("[#"..string.format("%04d", curIdx).."]\n")
				tempInFile:write("Length="..(g_inNoteList[idx].posTick - lastPos).."\n")
				lastPos = g_inNoteList[idx].posTick -1
				curIdx = curIdx + 1
				tempInFile:write("Lyric=R\n")
				tempInFile:write("NoteNum=60\n\n")

				--retCode, controlValTEMPO = VSGetControlAt(lastPos+1)
				--if(controlValTEMPO~=tempo.tempo) then
				--	tempInFile:write("Tempo="..(controlValTEMPO).."\n")
				--end

				if ((g_inNoteList[idx].posTick - lastPos) > 240 ) then
					lastisR = 1
				end
			end
			if (g_inNoteList[idx].phonemes~="-" ) then

				lastPos = g_inNoteList[idx].posTick + g_inNoteList[idx].durTick
				tempInFile:write("[#"..string.format("%04d", curIdx).."]\n")
				curIdx = curIdx + 1
				local nlength=g_inNoteList[idx].durTick
				tempInFile:write("Lyric="..g_inNoteList[idx].lyric.."\n")
				tempInFile:write("NoteNum="..g_inNoteList[idx].noteNum.."\n")
				tempInFile:write("Velocity="..(g_inNoteList[idx].velocity*1.27).."\n")
				
				--retCode, controlValTEMPO = VSGetControlAt(g_inNoteList[idx].posTick)
				--if(controlValTEMPO~=tempo.tempo) then
				--	tempInFile:write("Tempo="..(controlValTEMPO).."\n")
				--end
				local Flags="";
				local MidPos=(lastPos+g_inNoteList[idx].posTick)/2
				local TmpCtrl
				retCode, TmpCtrl = VSGetControlAt("BRE", MidPos)
				if(retCode==1) then
					if(TmpCtrl~=DefBRE)then
						Flags=Flags.."B"..TmpCtrl
					end
				end
				retCode, TmpCtrl = VSGetControlAt("GEN", MidPos)
				if(retCode==1) then
					if(TmpCtrl~=DefGEN)then
						local tp=TmpCtrl-64
						Flags=Flags.."g"..((tp))
					end
				end
				local Pettr=10
				-- tempInFile:write("PreUtterance="..Pettr.."\n")
				-- tempInFile:write("VoiceOverlap="..Pettr.."\n")
				-- tempInFile:write("Flags="..Flags.."\n")
				tempInFile:write("PBTYPE=5\n")
				tempInFile:write("PBStart=0\n")
				tempInFile:write("PitchBend=")

				local PitBendLine=""

				local MRV=(130/128)

				local pitc = getPOR(g_inNoteList[idx].posTick)*MRV 
				local pitb = getPOR(g_inNoteList[idx].posTick+g_inNoteList[idx].durTick)*MRV
				local allX=pitc+pitb
				local dex=g_inNoteList[idx].durTick-allX
				if (dex<0) then
					local pd=math.ceil(dex/2)-1
					pitc=pitc+pd
					pitb=pitb+pd
				end
				if (isFirst==1 or lastisR==1 or lastNote == g_inNoteList[idx].noteNum) then
					isFirst=0
					pitc=0
					lastisR = 0
				end
				
				if (pitc > 0) then
					local curNoteKey=0
					retCode, controlValPIT = VSGetControlAt("PIT", g_inNoteList[idx].posTick + pitc)
					retCode, controlValPBS = VSGetControlAt("PBS", g_inNoteList[idx].posTick + pitc)
					local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
					local Keys = (controlValPIT*100) / eachKey
					curNoteKey=Keys/100

					local dec = (lastNote+lastNoteKey - (g_inNoteList[idx].noteNum+curNoteKey))*100
					local xlen = pitc*2+(g_inNoteList[idx].posTick-oldlastPos)
					if (idx>1) then
						local allX=(getPOR(g_inNoteList[idx-1].posTick)+getPOR(g_inNoteList[idx-1].posTick+g_inNoteList[idx-1].durTick))*MRV
						local dex=g_inNoteList[idx-1].durTick-allX
						if (dex<0) then
							local pd=math.ceil(dex/2)-1
							pitc=pitc+pd
						end
					end
					local totalM=(pitc/5)*2
					local totalS=(pitc/5)
					local idx0

					local bendLength=0
					local totalM=(pitc/5)*2
					local totalS=((pitc*(1+bendLength))/5)
					local idx0

					local a=pitc*(1+bendLength)
					local b=0
							
					local pertX=(g_PI)/(xlen)
					local yardY=dec/2
					local midx=a-(xlen/2)
					local midy=b-yardY
					local lastKeyV=(lastNote+lastPointKey-g_inNoteList[idx].noteNum)*100

							local rX=a-(totalS)*5
							local pX=rX-midx
							local tY=yardY*math.sin(pertX*pX)
					local minKeyV=-midy-tY
					local decV1=math.abs(lastKeyV-minKeyV)
					local decV2=math.abs(lastKeyV+minKeyV)
					local bs=1
					if(decV1>decV2) then
						bs=-1
					end
					
					for idx0=0,totalS-1 do
						local CurPos=g_inNoteList[idx].posTick+idx0*5
						retCode, controlValPIT = VSGetControlAt("PIT", CurPos)
						if(controlValPIT == 0) then
							local rX=a-(totalS-idx0)*5
							local pX=rX-midx
							local tY=yardY*math.sin(pertX*pX)
							local rY=-midy-tY
							rY=rY*bs
							lastPointKey=rY/100
							PitBendLine=PitBendLine..string.format("%.2f", rY) .. ","
						else
							retCode, controlValPBS = VSGetControlAt("PBS", CurPos)
							local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
							local Keys = (controlValPIT*100) / eachKey
							lastNoteKey= Keys / 100
							lastPointKey=lastNoteKey
							-- tempInFile:write(string.format("%.2f", Keys) .. ",")
							PitBendLine=PitBendLine..string.format("%.2f", Keys) .. ","
						end
					end
				end

				if (idx+1 > g_inNoteListSize) then
					pitb=0
				else
					if (g_inNoteList[idx+1].posTick > lastPos + 480 ) then
						pitb=0
					end
				end 

				lastNote = g_inNoteList[idx].noteNum
				--if (g_inNoteList[idx].posTick + pitc - lastPos + pitb >0) then
					for posTick =g_inNoteList[idx].posTick + pitc, lastPos - pitb,5 do
							retCode, controlValPIT = VSGetControlAt("PIT", posTick)
							retCode, controlValPBS = VSGetControlAt("PBS", posTick)
							
							local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
							local Keys = (controlValPIT*100) / eachKey
							Keys=Keys+vibYValue(idx,posTick)
							lastNoteKey=Keys/100
							lastPointKey=lastNoteKey
							-- tempInFile:write(string.format("%.2f", Keys) .. ",")
							PitBendLine=PitBendLine..string.format("%.2f", Keys) .. ","
					end
				--end
				if (pitb > 0) then

					retCode, controlValPIT = VSGetControlAt("PIT", g_inNoteList[idx+1].posTick)
					retCode, controlValPBS = VSGetControlAt("PBS", g_inNoteList[idx+1].posTick)
					local eachKeyEx= 8192 / controlValPBS  -- X100 FOR FLOAT
					local KeysEx = (controlValPIT*100) / eachKeyEx
					local lastNoteKeyEx=KeysEx/100
					
					local dec = (g_inNoteList[idx].noteNum - g_inNoteList[idx+1].noteNum - lastNoteKeyEx)*100
					local xlen = pitb*2+(g_inNoteList[idx+1].posTick-lastPos)

					local bendLength=0
					local totalM=(pitb/5)*2
					local totalS=((pitb*(1+bendLength))/5)
					local idx0

					
					local a=pitb*(1+bendLength)
					local b=0
							
					local pertX=(g_PI)/(xlen)
					local yardY=dec/2
					local midx=a-(xlen/2)
					local midy=b-yardY

					for idx0=0,totalS-1 do
					
						local CurPos=lastPos - pitb+idx0*5
						retCode, controlValPIT = VSGetControlAt("PIT", CurPos)
						if(controlValPIT == 0 or idx0>totalS-1) then
							-- tempInFile:write(string.format("%.2f", dec * ((-idx0)/totalM)) .. ",")
							local rX=a+(idx0*5)
							local pX=midx-rX
							local tY=yardY*math.sin(pertX*pX)
							local rY=midy-tY
							PitBendLine=PitBendLine..string.format("%.2f", rY) .. ","
							lastPointKey=rY/100
						else
							retCode, controlValPBS = VSGetControlAt("PBS", CurPos)
							local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
							local Keys = (controlValPIT*100) / eachKey
							lastNoteKey=Keys/100
							lastPointKey=lastNoteKey
							-- tempInFile:write(string.format("%.2f", Keys) .. ",")
							PitBendLine=PitBendLine..string.format("%.2f", Keys) .. ","
						end
					end
				end


			        oldlastPos=lastPos
				local nextP=0
				-- local newIdx = idx
				for nextP=idx+1,g_inNoteListSize do
					if(g_inNoteList[nextP].phonemes=="-")then
							nlength=nlength+g_inNoteList[nextP].durTick
							local pita= getPOR(g_inNoteList[nextP].posTick)*MRV
							local hnext= getPOR(g_inNoteList[nextP].posTick+g_inNoteList[nextP].durTick)*MRV
							local allX=pita+hnext
							local dex=g_inNoteList[nextP].durTick-allX
							if (dex<0) then
								local pd=math.ceil(dex/2)-1
								pita=pita+pd
								hnext=hnext+pd
							end

							local curNoteKey=0
							retCode, controlValPIT = VSGetControlAt("PIT", g_inNoteList[nextP].posTick + pita)
							retCode, controlValPBS = VSGetControlAt("PBS", g_inNoteList[nextP].posTick + pita)
							local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
							local Keys = (controlValPIT*100) / eachKey
							curNoteKey=Keys/100

							local dec2 = (g_inNoteList[nextP-1].noteNum + lastNoteKey - (g_inNoteList[nextP].noteNum+curNoteKey))*100
							local dec3 = (g_inNoteList[idx].noteNum - g_inNoteList[nextP].noteNum)*100
							
							local xlen = pita*2+(g_inNoteList[nextP].posTick-oldlastPos)
						
								local allX=(getPOR(g_inNoteList[nextP-1].posTick)+getPOR(g_inNoteList[nextP-1].posTick+g_inNoteList[nextP-1].durTick))*MRV
								local dex=g_inNoteList[nextP-1].durTick-allX
								if (dex<0) then
									local pd=math.ceil(dex/2)-1
									xlen=xlen+pd
									pita=pita+pd
								end
						
							local bendLength=0
							
							local totalM=(pita/5)*2
							local totalS=((pita*(1+bendLength))/5)
							local idx0

								
							local a=pita*(1+bendLength)
							local b=0	
							local pertX=(g_PI)/(xlen)
							local yardY=dec2/2
							local midx=a-(xlen/2)
							local midy=b-yardY

							
							local lastKeyV=(lastPointKey)*100

							local rX=a-(totalS)*5
							local pX=rX-midx
							local tY=yardY*math.sin(pertX*pX)

							local minKeyV=-midy-tY-dec3
							local decV1=math.abs(lastKeyV-minKeyV)
							local decV2=math.abs(lastKeyV+minKeyV)
							local bs=1
							if(decV1>decV2) then
								bs=-1
							end

							for idx0=0,totalS-1 do
								local CurPos=g_inNoteList[nextP].posTick+idx0*5
								retCode, controlValPIT = VSGetControlAt("PIT", CurPos)
								if(controlValPIT == 0) then
									-- tempInFile:write(string.format("%.2f", dec2 * ((totalS-idx0)/totalM)-dec3) .. ",")
									local rX=a-(totalS-idx0)*5
									local pX=rX-midx
									local tY=yardY*math.sin(pertX*pX)
									local rY=-midy-tY
									rY=rY*bs
									lastPointKey=(rY-dec3)/100
									PitBendLine=PitBendLine..string.format("%.2f", rY-dec3) .. ","
								else
									retCode, controlValPBS = VSGetControlAt("PBS", CurPos)
									local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
									local Keys = (controlValPIT*100) / eachKey
									lastNoteKey=Keys/100
									lastPointKey=(Keys-dec3)/100
									-- tempInFile:write(string.format("%.2f", Keys - dec3) .. ",")
									PitBendLine=PitBendLine..string.format("%.2f", Keys - dec3) .. ","
								end
							end


							if(nextP+1 >g_inNoteListSize) then
								hnext=0
							else
								-- if(g_inNoteList[nextP+1].phonemes~="-") then
								--	hnext=0
								-- end
							end
							--if((g_inNoteList[nextP].posTick + pita - (g_inNoteList[nextP].posTick+g_inNoteList[nextP].durTick) + hnext)>0)then
								for posTick =g_inNoteList[nextP].posTick + pita, (g_inNoteList[nextP].posTick+g_inNoteList[nextP].durTick) - hnext,5 do
										retCode, controlValPIT = VSGetControlAt("PIT", posTick)
										retCode, controlValPBS = VSGetControlAt("PBS", posTick)

										local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
										local Keys = (controlValPIT*100) / eachKey
										lastNoteKey=Keys/100
										lastPointKey=(Keys-dec3)/100
										-- tempInFile:write(string.format("%.2f", Keys - dec3) .. ",")
										PitBendLine=PitBendLine..string.format("%.2f", Keys - dec3) .. ","
								end
							--end
							
							if (hnext ~= 0) then
								retCode, controlValPIT = VSGetControlAt("PIT", g_inNoteList[nextP+1].posTick)
								retCode, controlValPBS = VSGetControlAt("PBS", g_inNoteList[nextP+1].posTick)
								local eachKeyEx= 8192 / controlValPBS  -- X100 FOR FLOAT
								local KeysEx = (controlValPIT*100) / eachKeyEx
								local lastNoteKeyEx=KeysEx/100

								local dec2 = (g_inNoteList[nextP].noteNum - g_inNoteList[nextP+1].noteNum - lastNoteKeyEx)*100
								local dec3 = (g_inNoteList[idx].noteNum - g_inNoteList[nextP].noteNum)*100
								local xlen = hnext*2+(g_inNoteList[nextP+1].posTick-g_inNoteList[nextP].posTick-g_inNoteList[nextP].durTick)
								local bendLength=0
								local totalM=(hnext/5)*2
								local totalS=((hnext*(1+bendLength))/5)
								local idx0

								local a=g_inNoteList[nextP].posTick+g_inNoteList[nextP].durTick-(hnext*(1+bendLength))
								local b=0
								local pertX=(g_PI)/(xlen)
								local yardY=dec2/2
								local midx=a-(xlen/2)
								local midy=b-yardY

								for idx0=0,totalS-1 do
								
									local CurPos=(g_inNoteList[nextP].posTick+g_inNoteList[nextP].durTick) - hnext + idx0*5
									retCode, controlValPIT = VSGetControlAt("PIT", CurPos)
									if(controlValPIT == 0 or idx0>totalS-1) then
										-- tempInFile:write(string.format("%.2f", dec2 * ((-idx0)/totalM)-dec3) .. ",")
										local rX=a+(idx0*5)
										local pX=midx-rX
										local tY=yardY*math.sin(pertX*pX)
										local rY=midy-tY
										lastPointKey=(rY-dec3)/100
										PitBendLine=PitBendLine..string.format("%.2f", rY-dec3) .. ","
									else
										retCode, controlValPBS = VSGetControlAt("PBS", CurPos)
										local eachKey= 8192 / controlValPBS  -- X100 FOR FLOAT
										local Keys = (controlValPIT*100) / eachKey
										lastNoteKey=Keys/100
										lastPointKey=(Keys-dec3)/100
										-- tempInFile:write(string.format("%.2f", Keys-dec3) .. ",")
										PitBendLine=PitBendLine..string.format("%.2f", Keys-dec3) .. ","
									end

								end
							end

							lastNote = g_inNoteList[nextP].noteNum
							lastPos = g_inNoteList[nextP].posTick + g_inNoteList[nextP].durTick
							oldlastPos=lastPos
							nlength = lastPos - g_inNoteList[idx].posTick
						--newIdx=newIdx+1	
					else
						break
					end
				end
				-- idx=newIdx
				tempInFile:write(string.sub(PitBendLine,1,string.len(PitBendLine)-1) .. "\n")
				tempInFile:write("Length="..(nlength).."\n")
				
				--BUILD WAVTOOL2ENV
				local Volu=""
				local StartPos=g_inNoteList[idx].posTick
				local EndPos= StartPos + nlength
				local idxZ=0
				local Finded=0
				for idxZ=DYNHandle,DYNSize do
					if(idxZ==0)then
					break
					end
					if (StartPos <= DYNList[idxZ].posTick) and (Finded==0) then
						Finded=1
						tempInFile:write("Flags=v1\n")
						local TP1
						retCode, TP1 = VSGetControlAt("DYN", StartPos)
						Volu=Volu.."1,"..math.ceil((TP1/127)*200)
					end
					if ((StartPos <= DYNList[idxZ].posTick) and (DYNList[idxZ].posTick <= EndPos)) then
						local DPos=DYNList[idxZ].posTick-StartPos
						local DValue=DYNList[idxZ].value
						local RValue=(DValue/127)*200
						if(DPos==0)then
							DPos=1
						end
						Volu=Volu..","..DPos..","..math.ceil(RValue)
					else
						if (Finded==1) then
							break
						end
					end
					DYNHandle=DYNHandle+1
				end
				if (Finded==1) then
					local TP1
					retCode, TP1 = VSGetControlAt("DYN", EndPos)
					Volu=Volu..","..EndPos..","..math.ceil((TP1/127)*200)
					tempInFile:write("$volume="..Volu.."\n")
				end
				--Envelope=x1,x2,x4,y1,y2,y4,0,%,0,x3,y3
				if (nlength>=240) then
					local Dx1=10
					local Dy1=math.ceil((VSGetControlAtPos("DYN", StartPos+Dx1)/127)*200)
					local Dx4=35
					local Dy4=math.ceil((VSGetControlAtPos("DYN", EndPos-Dx4)/127)*200)
					local CDec=nlength-10-35 - 20 -- 20 is DecXwei
					if(CDec>3)then
						local mDec=math.ceil(CDec/3)
						local Dx2=mDec
						local Dy2=math.ceil((VSGetControlAtPos("DYN", StartPos+Dx1+mDec)/127)*200)
						-- local Dx3=mDec
						-- local Dy3=math.ceil((VSGetControlAtPos("DYN", StartPos+Dx2+mDec)/127)*200)
						tempInFile:write("Envelope="..Dx1..","..Dx2..","..Dx4..","..Dy1..","..Dy2..","..Dy4..",0,%,0".."\n\n") -- ..Dx3..","..Dy3
					end
				end
				
			end


		end
		end
	end

						tempInFile:write("[#TRACKEND]\n")

	-- ぼかりす本体へ入力するテンポラリファイルをクローズする.
	tempInFile:flush()
	tempInFile:close()

	return STATUS_NORMAL
end

function VSGetControlAtPos(AttrName,PosTick)
	local TP1
	retCode, TP1 = VSGetControlAt(AttrName,PosTick)
	if (retCode==1) then
		return TP1
	else
		return 0
	end
end

--
-- End of UTAUExporter.lua
--
