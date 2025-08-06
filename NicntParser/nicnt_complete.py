#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
NICNT 完整解析器 - 唯一的工作脚本
结合所有功能：UTF-16文件名提取 + 真实文件数据提取 + 正确目录结构
"""

import os
import struct
import re
from pathlib import Path

class NicntCompleteParser:
    """完整的NICNT解析器"""
    
    def __init__(self):
        self.file_paths = {}  # 存储UTF-16提取的真实文件路径
        self.file_data_map = {}  # 存储文件数据位置
        
    def extract_real_filenames_from_toc(self, data: bytes, toc_pos: int):
        """从TOC中提取UTF-16编码的真实文件名"""
        print("🔍 从TOC提取真实文件名...")
        
        # UTF-16文件扩展名模式
        extensions = [
            (b'.\x00p\x00n\x00g\x00', '.png'),
            (b'.\x00d\x00b\x00', '.db'),
            (b'.\x00m\x00e\x00t\x00a\x00', '.meta'),
            (b'.\x00c\x00a\x00c\x00h\x00e\x00', '.cache'),
            (b'.\x00w\x00e\x00b\x00p\x00', '.webp')
        ]
        
        real_filenames = []
        for ext_bytes, ext_name in extensions:
            pos = toc_pos
            while True:
                pos = data.find(ext_bytes, pos)
                if pos == -1:
                    break
                
                # 向前搜索文件名开始位置
                start = pos - 150
                while start < pos and start >= 0:
                    if (start % 2 == 0 and start + 1 < len(data) and
                        data[start + 1] == 0 and 32 <= data[start] <= 126):
                        char = chr(data[start])
                        if char == '.' or char.isalnum():
                            try:
                                utf16_data = data[start:pos + len(ext_bytes)]
                                filename = utf16_data.decode('utf-16le').rstrip('\x00')
                                if filename and '.' in filename and len(filename) <= 80:
                                    filename_clean = filename.replace('|', '[pipe]')
                                    self.file_paths[start] = filename_clean
                                    real_filenames.append(filename_clean)
                                    print(f"   ✅ {filename_clean}")
                                    break
                            except:
                                pass
                    start += 2
                pos += 1
        
        return real_filenames
    
    def find_file_data_positions(self, data: bytes):
        """基于Hex分析的精确文件定位"""
        print("🎯 基于Hex分析精确定位文件数据...")
        
        file_positions = []
        
        # SQLite数据库 - 使用头部信息计算真实大小
        pos = 0
        db_index = 1
        while True:
            pos = data.find(b'SQLite format 3', pos)
            if pos == -1:
                break
            
            if pos + 100 < len(data):
                try:
                    header = data[pos:pos+100]
                    # 读取页大小 (offset 16-17)
                    page_size_raw = struct.unpack('>H', header[16:18])[0]
                    page_size = 65536 if page_size_raw == 1 else page_size_raw
                    # 读取数据库页数 (offset 28-31)
                    page_count = struct.unpack('>I', header[28:32])[0]
                    # 计算真实文件大小
                    real_size = page_size * page_count
                    
                    if pos + real_size <= len(data):
                        file_positions.append({
                            'start': pos,
                            'end': pos + real_size,
                            'size': real_size,
                            'type': '.db',
                            'signature': b'SQLite format 3',
                            'real_size': True,
                            'db_index': db_index
                        })
                        print(f"   SQLite #{db_index}: {real_size:,} bytes @ 0x{pos:08x}")
                        db_index += 1
                except:
                    pass
            pos += 1
        
        # PNG文件 - 查找IEND标记
        pos = 0
        png_index = 1
        while True:
            pos = data.find(b'\x89PNG', pos)
            if pos == -1:
                break
            
            end_pos = data.find(b'IEND', pos)
            if end_pos >= 0:
                end_pos += 8  # IEND + CRC
                file_positions.append({
                    'start': pos,
                    'end': end_pos,
                    'size': end_pos - pos,
                    'type': '.png',
                    'signature': b'\x89PNG',
                    'real_size': True,
                    'png_index': png_index
                })
                print(f"   PNG #{png_index}: {end_pos - pos:,} bytes @ 0x{pos:08x}")
                png_index += 1
            pos += 1
        
        # WEBP文件 - RIFF容器解析
        pos = 0
        webp_index = 1
        while True:
            pos = data.find(b'RIFF', pos)
            if pos == -1:
                break
            
            if pos + 12 < len(data) and data[pos+8:pos+12] == b'WEBP':
                try:
                    webp_size = struct.unpack('<I', data[pos+4:pos+8])[0] + 8
                    if pos + webp_size <= len(data):
                        file_positions.append({
                            'start': pos,
                            'end': pos + webp_size,
                            'size': webp_size,
                            'type': '.webp',
                            'signature': b'RIFF',
                            'real_size': True,
                            'webp_index': webp_index
                        })
                        print(f"   WEBP #{webp_index}: {webp_size:,} bytes @ 0x{pos:08x}")
                        webp_index += 1
                except:
                    pass
            pos += 1
        
        # 按位置排序
        file_positions.sort(key=lambda x: x['start'])
        print(f"   总计发现 {len(file_positions)} 个精确数据文件")
        return file_positions
    
    def find_meta_contents(self, data: bytes):
        """查找META文件的真实XML内容"""
        print("🔍 查找META文件真实内容...")
        
        meta_contents = []
        pos = 0
        while True:
            pos = data.find(b'<?xml', pos)
            if pos == -1:
                break
            
            # 查找XML结束标记
            possible_endings = [
                b'</resource>',
                b'</ProductHints>',
                b'</metadata>',
                b'</soundinfos>'
            ]
            
            xml_end = -1
            for ending in possible_endings:
                end_pos = data.find(ending, pos)
                if end_pos != -1 and (xml_end == -1 or end_pos < xml_end):
                    xml_end = end_pos + len(ending)
            
            if xml_end != -1:
                xml_content = data[pos:xml_end]
                try:
                    xml_text = xml_content.decode('utf-8', errors='ignore')
                    
                    # 处理不同类型的XML内容
                    if b'<resource' in xml_content:
                        # META资源类型
                        name_match = re.search(r'<name>([^<]+)</name>', xml_text)
                        type_match = re.search(r'<type>([^<]+)</type>', xml_text)
                        
                        if name_match and type_match:
                            meta_contents.append({
                                'start': pos,
                                'end': xml_end,
                                'size': len(xml_content),
                                'content': xml_text,
                                'name': name_match.group(1),
                                'type': type_match.group(1),
                                'file_type': 'meta'
                            })
                            print(f"   META: {name_match.group(1)} ({type_match.group(1)}) - {len(xml_content)} bytes")
                    
                    elif b'<soundinfos' in xml_content:
                        # .db.cache文件
                        meta_contents.append({
                            'start': pos,
                            'end': xml_end,
                            'size': len(xml_content),
                            'content': xml_text,
                            'name': 'cache',
                            'type': 'cache',
                            'file_type': 'cache'
                        })
                        print(f"   CACHE: soundinfos - {len(xml_content)} bytes")
                    
                except Exception as e:
                    pass
            
            pos += 1
        
        print(f"   总计发现 {len(meta_contents)} 个META文件")
        return meta_contents
    
    def match_filenames_to_data(self, real_filenames, file_positions):
        """匹配真实文件名到文件数据"""
        print("🔗 匹配文件名到数据...")
        
        matched_files = []
        
        # 按文件类型分组
        png_files = [f for f in real_filenames if f.endswith('.png')]
        db_files = [f for f in real_filenames if f.endswith('.db')]
        meta_files = [f for f in real_filenames if f.endswith('.meta')]
        cache_files = [f for f in real_filenames if f.endswith('.cache')]
        webp_files = [f for f in real_filenames if f.endswith('.webp')]
        
        png_positions = [p for p in file_positions if p['type'] == '.png']
        db_positions = [p for p in file_positions if p['type'] == '.db']
        webp_positions = [p for p in file_positions if p['type'] == '.webp']
        
        # 匹配PNG文件
        for i, png_name in enumerate(png_files):
            if i < len(png_positions):
                matched_files.append({
                    'name': png_name,
                    'data_pos': png_positions[i]
                })
        
        # 匹配DB文件
        for i, db_name in enumerate(db_files):
            if i < len(db_positions):
                matched_files.append({
                    'name': db_name,
                    'data_pos': db_positions[i]
                })
        
        # 匹配WEBP文件
        for i, webp_name in enumerate(webp_files):
            if i < len(webp_positions):
                matched_files.append({
                    'name': webp_name,
                    'data_pos': webp_positions[i]
                })
        
        # META和CACHE文件没有二进制数据，创建占位文件
        for meta_name in meta_files:
            matched_files.append({
                'name': meta_name,
                'data_pos': {'start': 0, 'end': 0, 'size': 0, 'type': '.meta'}
            })
        
        for cache_name in cache_files:
            matched_files.append({
                'name': cache_name,
                'data_pos': {'start': 0, 'end': 0, 'size': 0, 'type': '.cache'}
            })
        
        print(f"   匹配成功 {len(matched_files)} 个文件")
        return matched_files
    
    def create_directory_structure(self, output_dir, filename):
        """根据正确的结构：Resources目录下直接放文件，保持[pipe]文件名"""
        # 所有文件都直接放在Resources目录下，文件名保持[pipe]格式
        resources_dir = os.path.join(output_dir, "Resources")
        os.makedirs(resources_dir, exist_ok=True)
        return resources_dir, filename
    
    def extract_complete_nicnt(self, nicnt_path, output_base_name):
        """完整的NICNT文件提取"""
        print("🚀 NICNT完整解析器启动")
        print("=" * 60)
        
        # 读取文件
        with open(nicnt_path, 'rb') as f:
            data = f.read()
        
        print(f"📁 源文件: {nicnt_path}")
        print(f"📊 大小: {len(data):,} bytes")
        
        # 创建输出目录
        output_dir = f"/mnt/c/Code/Electron/KontaktMax/Test/{output_base_name}_complete"
        os.makedirs(output_dir, exist_ok=True)
        print(f"📂 输出目录: {output_dir}")
        
        # 查找TOC位置
        toc_marker = b"/\\ NI FC TOC  /\\"
        toc_pos = data.find(toc_marker)
        if toc_pos == -1:
            print("❌ 未找到TOC标识符")
            return
        
        print(f"🔍 TOC位置: {toc_pos}")
        
        # 提取真实文件名
        real_filenames = self.extract_real_filenames_from_toc(data, toc_pos)
        
        # 查找文件数据位置
        file_positions = self.find_file_data_positions(data)
        
        # 查找META内容
        meta_contents = self.find_meta_contents(data)
        
        # 匹配文件名到数据
        matched_files = self.match_filenames_to_data(real_filenames, file_positions)
        
        # 添加META文件和CACHE文件到匹配结果
        for meta in meta_contents:
            if meta['file_type'] == 'cache':
                # .db.cache文件
                cache_filename = '.db.cache'
                if cache_filename in real_filenames:
                    matched_files.append({
                        'name': cache_filename,
                        'data_pos': {
                            'start': meta['start'],
                            'end': meta['end'],
                            'size': meta['size'],
                            'type': '.cache',
                            'content': meta['content']
                        }
                    })
                    print(f"   ✅ 匹配CACHE: {cache_filename}")
            else:
                # META文件
                if meta['type'] == '_DatabaseResources':
                    meta_filename = f".PAResources[pipe]_DatabaseResources[pipe]{meta['name']}[pipe]{meta['name']}.meta"
                elif meta['type'] == 'database':
                    meta_filename = f".PAResources[pipe]database[pipe]PAL[pipe]{meta['name']}.meta"
                elif meta['type'] == 'image':
                    meta_filename = f".PAResources[pipe]image[pipe]40s Very Own - Drums[pipe]{meta['name']}.meta"
                else:
                    meta_filename = f"{meta['name']}.meta"
                
                # 检查是否在真实文件名列表中
                if meta_filename in real_filenames:
                    matched_files.append({
                        'name': meta_filename,
                        'data_pos': {
                            'start': meta['start'],
                            'end': meta['end'],
                            'size': meta['size'],
                            'type': '.meta',
                            'content': meta['content']
                        }
                    })
                    print(f"   ✅ 匹配META: {meta_filename}")
        
        # 提取XML和产品名
        xml_start = data.find(b'<?xml')
        product_name = output_base_name
        if xml_start >= 0:
            xml_end = data.find(b'</ProductHints>', xml_start)
            if xml_end >= 0:
                xml_end += len(b'</ProductHints>')
                xml_data = data[xml_start:xml_end]
                xml_content = xml_data.decode('utf-8', errors='ignore')
                
                name_match = re.search(r'<Name>([^<]+)</Name>', xml_content)
                if name_match:
                    product_name = name_match.group(1).strip()
                
                # 保存XML文件
                xml_path = os.path.join(output_dir, f"{product_name}.xml")
                with open(xml_path, 'wb') as f:
                    f.write(xml_data)
                print(f"   ✅ {product_name}.xml ({len(xml_data)} bytes)")
        
        # 创建ContentVersion.txt
        content_version_path = os.path.join(output_dir, "ContentVersion.txt")
        with open(content_version_path, 'w', encoding='utf-8') as f:
            f.write("1.0.0\n")
        print(f"   ✅ ContentVersion.txt")
        
        # 保存所有匹配的文件
        saved_count = 2  # XML + ContentVersion
        print(f"\n💾 保存文件到正确的目录结构...")
        
        for file_info in matched_files:
            filename = file_info['name']
            data_pos = file_info['data_pos']
            
            try:
                # 创建目录结构
                target_dir, final_filename = self.create_directory_structure(output_dir, filename)
                file_path = os.path.join(target_dir, final_filename)
                
                if (data_pos['type'] == '.meta' or data_pos['type'] == '.cache') and 'content' in data_pos:
                    # META/CACHE文件，保存真实XML内容
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(data_pos['content'])
                    file_type_name = "真实META" if data_pos['type'] == '.meta' else "真实CACHE"
                    print(f"   ✅ {filename} ({len(data_pos['content'])} bytes) [{file_type_name}]")
                elif data_pos['size'] > 0:
                    # 有实际二进制数据的文件
                    file_data = data[data_pos['start']:data_pos['end']]
                    with open(file_path, 'wb') as f:
                        f.write(file_data)
                    print(f"   ✅ {filename} ({len(file_data):,} bytes)")
                else:
                    # CACHE等文件，创建占位符
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(f"# {filename} placeholder\n")
                    print(f"   ✅ {filename} (placeholder)")
                
                saved_count += 1
                
            except Exception as e:
                print(f"   ❌ 保存 {filename} 失败: {e}")
        
        # 显示最终结果
        print(f"\n📈 提取完成!")
        print(f"   • 总文件数: {saved_count}")
        print(f"   • 真实文件名: {len(real_filenames)}")
        print(f"   • 产品名: {product_name}")
        
        print(f"\n🎉 所有文件已保存到:")
        print(f"📂 {output_dir}")
        
        return output_dir

def main():
    """主函数"""
    parser = NicntCompleteParser()
    
    nicnt_file = "/mnt/c/Code/Electron/KontaktMax/Test/40s Very Own - Drums.nicnt"
    base_name = "40s Very Own - Drums"
    
    result_dir = parser.extract_complete_nicnt(nicnt_file, base_name)
    
    print(f"\n✨ 使用Windows文件管理器查看结果:")
    windows_path = result_dir.replace('/mnt/c/', 'C:\\').replace('/', '\\')
    print(f"📁 {windows_path}")

if __name__ == "__main__":
    main()