# Window Screenshot Skill

Windows 窗口截图工具，使用 Win32 API 捕获物理分辨率截图。

## 原理

```
1. 获取窗口句柄
   └─ MainWindowHandle → 若无效则枚举进程窗口
   
2. 窗口聚焦
   └─ SetForegroundWindow() + 50ms 等待
   
3. 坐标转换
   └─ 物理坐标 = 逻辑坐标 × 缩放比例 (2560/屏幕宽度)
   
4. 截图
   └─ BitBlt 从 Desktop DC 复制物理坐标区域
```

## 使用

```bash
# 全屏截图
powershell -File screenshot.ps1 -FullScreen

# 窗口截图
powershell -File screenshot.ps1 -WindowName "QQMusic"
```

## 输出

```
SUCCESS: path/to/screenshot.png
WINDOW_TITLE: 窗口标题
```

## 坐标说明

- 屏幕逻辑分辨率：从 Screen.PrimaryScreen 获取
- 物理分辨率：固定 2560×1600
- 缩放比例：1.5 (2560/1707)

## 适用场景

- 普通窗口
- QQMusic 等特殊窗口（枚举解决）
- 前台/后台窗口（聚焦后均可截图）
