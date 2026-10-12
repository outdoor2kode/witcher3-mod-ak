// gunforgeralt M1 測試：確認 workspace\scripts\local\ 的腳本會被遊戲載入。
// 暫時檔案，確認後刪除。
exec function gfg_hello()
{
	GetWitcherPlayer().DisplayHudMessage("gunforgeralt: workspace scripts loaded");
}
