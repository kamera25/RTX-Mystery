-----------------------------------------------
-- ヤマハルータ向け、ゲーム制作モジュール
--
-- ヤマハルータで動作するゲーム関連をまとめたモジュール
-- こんなスーパーニッチなソースコードを見てくれて、ありがとう。
--
-- 参考 : http://www.rtpro.yamaha.co.jp/RT/docs/lua/rt_api.html
-----------------------------------------------


-- 異常終了した事を通知して、プログラムを強制終了します。
-- 引数 : 表示させるメッセージ(String)
local function exceptionMsg(message)
    print(message)
    os.exit(1)
end

-- 異常終了した事を通知して、プログラムを強制終了します。
local function exception()
    local message = [[
想定されていない問題が発生しました。ゲームを中断します
※再度、同じプログラムを実行してください。

]]
    exceptionMsg(message)
end

-- 指定秒数待機します
-- 引数 : 秒(seconds/Integer)
function Wait(seconds)
    if IsRunYamahaRTX() then
        -- Yamahaルータで実行されている場合
        rt.sleep(seconds)
    else
        -- PCで実行されている場合
        local start = os.time()
        repeat until os.time() > start + seconds
    end
end

-- 指定ミリ秒数待機します
-- 引数 : ミリ秒(seconds/float)
function MiliWait(miliseconds)
    local RTX1210_MILIWAIT = 2000000
    local loopMax = RTX1210_MILIWAIT * miliseconds / 1000

    if IsRunYamahaRTX() then
        for i = 1, loopMax do
        end
    end
end

-- テキストを指定秒数だけ遅らせます。
-- 引数 : str 表示される「改行を含んだ文字列」
-- 引数 : waitSeconds 「表示を遅らせる秒数」
function PrintWithWaitTime(str, waitSeconds)
    for line in str:gmatch("(.-)\n") do
        print(line)
        Wait(waitSeconds)
    end
end

-- Configに書き込みを行います
-- PCで実行されている場合、同じファイル配下のテキストに書き込みます
-- 引数 : str Configに書き込みを行う文字列。つまりヤマハルータのコマンド名
function WriteConfig(str)
    if IsRunYamahaRTX() then
        -- Yamahaルータで実行されている場合
        local rtn, cmd = rt.command(str)
        if not rtn then
            exception()
        end
    else
        -- PCで実行されている場合
        local f = io.open('conf.txt', 'w')
        if f == nil then
            exception()
        end

        f:write(str)
        f:close()
    end
end

-- Playerの名前を設定します
-- 引数 : プレイヤーの名前(playerName)
function SetPlayerName(playerName)
    local f = OpenFile('gameSetting.txt', 'w')

    if f == nil then
        exception()
    end

    f:write(playerName)
    f:close()
end

-- Playerの名前を取得します
function GetPlayerName()
    local f = OpenFile('gameSetting.txt', 'r')

    if f == nil then
        exception()
    end

    local playerName = f:read('*a')
    f:close()

    return playerName
end

-- ヤマハRTXで改行ごとに音を鳴らします
-- 引数 : 楽譜データ(多重配列)
function PlayScoreByBuzzer(score)
    -- 定数
    local TONE_INDEX = 1
    local WAIT_INDEX = 2

    -- PCで実行されている場合
    if not IsRunYamahaRTX() then
        return --類似する処理は難しいのでスキップ
    end


    -- Yamahaルータで実行されている場合
    local bz, err = rt.hw.open("buzzer1")

    -- 音色を流す
    -- RTXでは次の音色だけ出せる B2、E3、B3、B4、NO
    if (bz) then
        for i = 1, #score do
            -- 無音の場合
            if score[i][TONE_INDEX] == "NO" then
                bz:off()
            else
                -- 音色を流す場合
                bz:tone(score[i][TONE_INDEX])
            end

            MiliWait(score[i][WAIT_INDEX])
        end

        bz:off()
        bz:close()
    end
end

-- ヤマハRTXでキーボード(PC)に応じた音を鳴らす処理
-- つまり、実質的にヤマハピアノ
-- 引数 : 演奏できる秒数(seconds)
function PlayYamahaPiano(seconds)
    -- 定数
    local TONE_INDEX = 1
    local WAIT_INDEX = 2

    local loopMax = seconds * 5

    -- PCで実行されている場合
    if not IsRunYamahaRTX() then
        return --類似する処理は難しいのでスキップ
    end

    -- 以下、Yamahaルータで実行されている場合の処理
    -- キーボードを利用する処理
    local kbd, errkbb = rt.hw.open("keyboard1", "jp")


    -- 以下、キーボードのハンドラーが取得できなかったときの処理
    if kbd == nil then
        -- TODO : あとで直す
        local message = [[
ジュンビ ヲ シテクダサイ
ワタシ ハ カレ ニ ハナムケ シタイノデス
        ]]
        exceptionMsg(message)
    end

    -- 以下、ブザーが取得できなかったときの処理
    -- ブザーを利用する処理
    local bz, err = rt.hw.open("buzzer1")
    if bz == nil then
        
        kbd:close()       
        -- TODO : あとで直す
        local message = [[
オト ヲ ナラス ブヒン ガ コワレタ
サイキドウ ヲ ネガイ
        ]]
        exceptionMsg(message)
    end


    for i = 1, loopMax do
        -- キーボードの入力情報を取得する(現在のキー入力を取得する)
        local keyInput = kbd:getc(true)

        if keyInput == "4" then        -- 低いシ
            bz:tone("B2")            
        elseif keyInput == "5" then    -- ミ
            bz:tone("E3")
        elseif keyInput == "6" then    -- シ
            bz:tone("B3")
        elseif keyInput == "+" then    -- 更に高いシ
            bz:tone("B4")
        else                            --判定外の
            bz:off()
        end

        MiliWait(200)
     end


    kbd:close()
    bz:close()
end

-- ヤマハRTXでLEDを光らせます
-- 引数 : LED情報(多重配列)
function ControlLED(ledData)
    -- 定数
    local LED_ONOFF_INDEX = 1
    local WAIT_INDEX = 2

    -- PCで実行されている場合
    if not IsRunYamahaRTX() then
        return --類似する処理は難しいのでスキップ
    end


    -- Yamahaルータで実行されている場合
    local bz, err = rt.hw.open("status-led1")

    -- 音色を流す
    -- RTXでは次の音色だけ出せる B2、E3、B3、B4、NO
    if (bz) then
        for i = 1, #ledData do
            -- 無音の場合
            if ledData[i][LED_ONOFF_INDEX] == "ON" then
                bz:on()
            else
                bz:off()
            end

            rt.sleep(ledData[i][WAIT_INDEX])
        end

        bz:off()
        bz:close()
    end
end

-- 実行環境に応じて、Openにするファイルを変更します
-- 引数 : filename : ファイル名
-- 引数 : mode : 動作モード
function OpenFile(filename, mode)
    local path = filename

    if IsRunYamahaRTX() then
        -- Yamahaルータで実行されている場合、usb1(USBメモリ)にアクセスする
        path = "usb1:/" .. filename
    end

    return io.open(path, mode)
end

-- ファイルが存在するか確認します。(boolean)
-- 引数 : filename : ファイル名
function IsExistFile(filename)
    local path = filename

    local isExist = false
    local f = io.open(path, "r")

    if f then
        isExist = true
        f:close()  -- ファイルを閉じる
    end

    return isExist
end

-- 実行環境に応じて、Openにするファイルを変更します
-- 引数 : filename : ファイル名
function OutputSyslog( severity, str)

    if IsRunYamahaRTX() then
        -- Yamahaルータで実行されている場合、普通にシスログに書く
        rt.syslog(severity, str)
    else
        -- PCで実行されている場合
        local f = io.open('syslog.log', 'a')
        if f == nil then
            exception()
        end

        f:write( severity, str)
        f:close()
    end

end

-- ファイルをUSBメモリからFlashのルートにコピーする
-- 引数 : path : ファイル名(on USBメモリ)
function CopyFileUSBtoFlash( path )
    
    if IsRunYamahaRTX() then
        -- Yamahaルータで実行されている場合、フラッシュにコピーする
        local command = "copy " .. path .. " /"
        rt.command(command)
    end
end

-- 実行環境がヤマハルータかどうかを判定します
function IsRunYamahaRTX()
    return _RT_FIRM_REVISION ~= nil
end
