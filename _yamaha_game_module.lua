-----------------------------------------------
-- ヤマハルータ向け、ゲーム制作モジュール
--
-- ヤマハルータで動作するゲーム関連をまとめたモジュール
-- こんなスーパーニッチなソースコードを見てくれて、ありがとう。
--
-- 参考 : http://www.rtpro.yamaha.co.jp/RT/docs/lua/rt_api.html
-----------------------------------------------

-- 異常終了した事を通知して、プログラムを強制終了します。
local function exception()
    local message = [[
        想定されていない問題が発生しました。ゲームを中断します
        ※再度、同じプログラムを実行してください。
    ]]
    print (message)
    os.exit(1)
end

-- 指定秒数待機します
-- 引数 : 秒(seconds)
function wait(seconds)
    -- ヤマハルータかどうか検知する。
    local firm = _RT_FIRM_REVISION

    -- PCで実行されている場合
    if firm == nil then
        local start = os.time()
        repeat until os.time() > start + seconds        
    else
    -- Yamahaルータで実行されている場合
        rt.sleep(seconds)
    end
end

-- テキストを指定秒数だけ遅らせます。
-- 引数 : str 表示される「改行を含んだ文字列」 
-- 引数 : waitSeconds 「表示を遅らせる秒数」
function printWithWaitTime( str, waitSeconds)

    for line in str:gmatch("(.-)\n") do
        print(line)
        wait(waitSeconds)
    end
end

-- Configに書き込みを行います
-- PCで実行されている場合、同じファイル配下のテキストに書き込みます
function writeConfig( str )
    -- ヤマハルータかどうか検知する。
    local firm = _RT_FIRM_REVISION

    -- PCで実行されている場合
    if firm == nil then
        local f = io.open('conf.txt', 'w')
        if f == nil then
            exception()
        end

        f:write(str)
        f:close()
    else
    -- Yamahaルータで実行されている場合
        rtn, str = rt.command(cmd)
        if (not rtn) or (not str) then
          exception()
        end
    end

end

-- Playerの名前を設定します
function setPlayerName( playerName )

    local f = io.open('gameSetting.txt', 'w')
    if f == nil then
        exception()
    end

    f:write(playerName)
    f:close()
end

-- Playerの名前を取得します
function getPlayerName()

    local f = io.open('gameSetting.txt', 'r')
    if f == nil then
        exception()
    end

    local playerName = f:read('a')
    f:close()

    return playerName
end

-- ヤマハRTXで改行ごとに音を鳴らします
-- 引数 : 楽譜データ(多重配列)
function playYamahaPiano( score )

    -- 定数
    local TONE_INDEX = 1
    local WAIT_INDEX = 2

    -- ヤマハルータかどうか検知する。
    local firm = _RT_FIRM_REVISION

    -- PCで実行されている場合
    if firm == nil then
        return --類似する処理は難しいのでスキップ
    else
    -- Yamahaルータで実行されている場合
        bz, err = rt.hw.open("buzzer1")

        -- 音色を流す
        -- RTXでは次の音色だけ出せる B2、E3、B3、B4
        if (bz) then
            for i = 1, #score do
                bz:tone(score[i][TONE_INDEX])
                rt.sleep(score[i][WAIT_INDEX])
            end

            bz:off()
            bz:close()
        end 
    end
end
