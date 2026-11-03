# 照片处理工具（macOS · 通用二进制：Apple Silicon + Intel）

考试**报名照片处理工具**的 macOS 移植版，**通用二进制（universal2）**——同一份 `.app`
同时适配 M 系列（arm64）和 Intel（x86_64）芯片。功能规格完整复刻自
Windows 原版（PhotoProcess 1.0，MFC + OpenCV 1.0）：选择证件照 → 自动校验 → 裁剪压缩为
约 10KB 的标准一寸照 `报名照片.JPG`。

技术栈：**Swift + SwiftUI + Vision + ImageIO**，全部使用系统框架，零第三方依赖。

## 功能与校验规则（与原版一致）

| 校验 | 规则 | 不通过时的提示（原版文案） |
|---|---|---|
| 格式 | 必须 JPG/JPEG | 打开照片文件类型不是JPG/JPEG格式，请选择JPG/JPEG格式照片文件。 |
| 像素 | 宽 ≥295、高 ≥413（一寸 300dpi，禁止放大低像素照片） | 打开照片文件像素数低。请选择高于或符合像素数要求的照片文件。 |
| 人像 | 正面人脸检测命中且恰好一张脸 | 打开照片文件不符合要求。请选择正面人像标准证件照片文件。 |
| 头部比例 | 人脸占比 ∈ [5%, 10%]（原 photo.ini `s_min`/`s_max`） | 打开照片文件人像头部比例不符合要求。请选择头部比例适当的照片文件。 |
| 亮度 | 人脸区域平均亮度 ∈ [0.1, 0.7]（原 `i_min`/`i_max`） | 同"人像"提示 |
| 背景 | 边框环判定为白色或蓝色 | 打开照片文件背景不符合要求。请选择白色或蓝色背景照片文件。 |

全部通过后：按证件照构图裁剪（人脸高约占画面 62%，人脸中心距顶约 42%）→ 缩放到
**295×413** → JPEG 二分质量搜索编码至 **≤10,240 字节（约 10KB）** → 保存为
`报名照片.JPG` → 提示"照片已保存成功，是否退出"。

阈值与参数集中在 `Sources/PhotoCore/PhotoConfig.swift`，与原版 `photo.ini` 一一对应。

## 构建

需要 macOS 13+ 与 Xcode 命令行工具（本仓库是 SwiftPM 工程，无需 .xcodeproj）：

```sh
swift test                                            # PhotoCore 单元测试
swift build -c release --arch arm64 --arch x86_64     # 构建 universal2（arm64 + Intel）
bash scripts/make-app-bundle.sh                       # 组装 照片处理工具.app + zip
```

### CI 构建（推荐）

- **GitHub Actions**（`.github/workflows/build.yml`）：push 到 `main` 即在 GitHub 托管的
  **Apple Silicon runner（macos-15）** 上跑测试、构建 universal2 并上传产物
  `PhotoTool-macOS-universal2.zip`（同时含 arm64 与 x86_64，Intel Mac 直接可用）；
  打 `v*` tag 会自动发布 Release。私有仓库注意 macOS runner 按 10 倍分钟计费。
- **GitLab CI**（`.gitlab-ci.yml`）：需要自建的、带 `macos` 标签的 Apple Silicon runner。

## 首次运行（未签名应用）

构建产物只做了 ad-hoc 签名，未做开发者签名/公证。首次打开：

- 右键 `.app` → **打开** → 再点"打开"；或
- 终端执行 `xattr -cr ~/Downloads/照片处理工具.app` 后双击打开。

正式分发需要 Apple Developer ID 签名 + 公证（`codesign --sign "Developer ID Application: …"`
与 `xcrun notarytool`），可自行在 CI 中追加。

## 与原版的差异（实现说明）

- **人脸检测**：用系统 Vision 框架替代 2005 年的 OpenCV Haar 级联，精度显著更高；
  Vision 框比 Haar 框更贴合，已用 `haarEquivalentAreaScale ≈ 1.4` 把面积换算回 Haar 口径，
  使 5%–10% 阈值语义与原版对齐。该系数是估计值（原版二进制未做函数级反编译）。
- **背景判定**：原版具体算法不可知，此处为边框环 HSL 多数表决（白/蓝各 ≥60%）。
- **JPEG 体积控制**：原版内嵌 libjpeg 自行控制；此处用 ImageIO 质量二分，目标 ≤10KB。
- 其余校验顺序、文案、输出文件名与尺寸严格复刻。

## 目录结构

```
Sources/PhotoCore/   纯逻辑库：阈值、校验、HSL/背景分类、裁剪数学（可单测）
Sources/PhotoTool/   SwiftUI 应用：界面、Vision 检测、像素采样、编码、文件面板
Tests/PhotoCoreTests/
scripts/make-app-bundle.sh
.github/workflows/build.yml   GitHub Actions（Apple Silicon runner）
.gitlab-ci.yml                GitLab CI（需自建 macOS runner）
```

## 来源与使用范围

功能规格通过静态逆向从 Windows 原版（考试机构公开发布的免费实用程序）恢复：
使用说明文档、`photo.ini`、PE 导入表与程序内嵌文案交叉印证。本项目供个人在
macOS 上使用；对外分发前请自行确认相应授权。
