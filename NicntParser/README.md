# NICNT Parser

基于 KoEd 库的发现，扩展实现的完整 .nicnt 文件解析和提取工具。

## 功能特性

- **完整文件提取**: 提取 .nicnt 文件中的所有资源文件
- **多格式支持**: 支持 PNG 图片、XML 元数据、SQLite 数据库等文件格式  
- **目录结构重建**: 重建原始的文件夹结构
- **TOC 解析**: 基于 KoEd 发现的 TOC (Table of Contents) 结构进行解析

## 基于的发现

本工具基于 KoEd 库已经发现的 .nicnt 文件结构：

1. **文件标识符**:
   - `"/\ NI FC MTD  /\"` - 数据段标识
   - `"/\ NI FC TOC  /\"` - 目录索引标识

2. **文件结构**:
   ```
   [256B] Bin 1 - 文件头信息
   [512000B] ProductHints XML - 产品元数据
   [256B] Bin 2 - 中间段信息  
   [可变] Bin 3 - TOC目录索引
   [可变] 各种资源文件 (PNG, DB, META等)
   ```

## 文件说明

- `nicnt_parser.py` - 主解析器代码
- `test_parser.py` - 测试和验证脚本
- `README.md` - 本说明文档

## 使用方法

### 1. 基本使用

```python
from nicnt_parser import NicntParser

# 创建解析器
parser = NicntParser()

# 解析文件并提取内容
entries = parser.parse_nicnt("path/to/library.nicnt")
```

### 2. 命令行测试

```bash
# 解析指定文件
python test_parser.py "path/to/library.nicnt"

# 分析文件结构 (调试用)
python test_parser.py "path/to/library.nicnt" --analyze

# 交互式模式
python test_parser.py
```

### 3. 输出结果

解析成功后会在原文件同目录下创建 `[文件名]_extracted` 文件夹，包含：

```
library_extracted/
├── Resources/           # 资源文件夹
│   ├── image_001.png   # 提取的图片文件
│   ├── image_002.png   
│   ├── database_001.db # SQLite 数据库文件
│   └── ...
├── metadata_001.xml    # XML 元数据文件
├── metadata_002.xml
└── ...
```

## 提取的文件类型

- **PNG 图片**: 音色库封面、界面图片等
- **XML 文件**: 产品信息、音色库元数据等
- **SQLite 数据库**: 音色索引、分类信息等
- **其他资源文件**: META、CACHE 等

## 解析原理

1. **标识符定位**: 使用 KoEd 发现的标识符定位各个数据段
2. **TOC 解析**: 解析目录索引获取文件列表信息
3. **内容扫描**: 扫描数据中的文件头标识 (PNG, XML, SQLite等)
4. **文件提取**: 根据偏移量和大小提取完整文件
5. **结构重建**: 重建原始的文件夹结构

## 扩展 KoEd 的功能

相比 KoEd 库只提取 3-4 个文件，本工具能够：

- 提取**所有**PNG 图片文件 (不只是 Wallpaper)
- 提取**所有**数据库文件 (.db 文件)
- 提取**所有**元数据文件 (.meta 文件)
- 重建完整的文件夹结构
- 自动识别和分类不同文件类型

## 技术细节

### TOC 结构解析

基于 KoEd 的注释，TOC 结构包含：
- 文件计数信息
- 每个文件的索引条目 (640B)
- 文件名和扩展名信息

### 文件类型识别

- **PNG**: `\x89PNG` 文件头
- **XML**: `<?xml` 开始标识
- **SQLite**: `SQLite format 3` 标识
- **其他**: 基于文件内容特征识别

## 调试和测试

使用 `--analyze` 参数可以分析文件结构：

```bash
python test_parser.py "library.nicnt" --analyze
```

这会显示：
- 文件大小信息
- 各种标识符的位置
- 文件头的十六进制内容
- ASCII 字符分析

## 依赖要求

- Python 3.7+
- 标准库 (无需额外安装依赖)

## 后续改进

- [ ] 支持更多文件格式识别
- [ ] 改进 TOC 解析准确性
- [ ] 添加文件完整性验证
- [ ] 支持文件重新打包
- [ ] GUI 界面支持