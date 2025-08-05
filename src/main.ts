import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import { invoke } from '@tauri-apps/api/core';
import { open } from '@tauri-apps/plugin-shell';

interface LibraryInfo {
    name: string;
    library_type: string;
    registration_status: string;
}

interface LibraryDetails {
    name: string;
    paths: string[];
    content_dir: string | null;
}

interface LibraryQueryResult {
    libraries: LibraryInfo[];
    total_count: number;
    standard_count: number;
    custom_count: number;
}

// --- Global State ---
let currentLibraries: LibraryInfo[] = [];
let sortState = { column: 'name', order: 'asc' };

// --- DOM Elements ---
let headerTable: HTMLTableElement | null;
let bodyTableBody: HTMLTableSectionElement | null;
let summaryElement: HTMLElement | null;
let infoHeader: HTMLElement | null;
let infoPlaceholder: HTMLElement | null;
let tabNav: HTMLElement | null;
let tabContent: HTMLElement | null;
let headerWrapper: HTMLElement | null;
let bodyWrapper: HTMLElement | null;

function initializeDOMElements() {
    headerTable = document.getElementById('header-table') as HTMLTableElement;
    bodyTableBody = document.querySelector('#body-table tbody');
    summaryElement = document.getElementById('library-summary');
    infoHeader = document.getElementById('info-header');
    infoPlaceholder = document.getElementById('info-placeholder');
    tabNav = document.querySelector('.tab-nav');
    tabContent = document.querySelector('.tab-content');
    headerWrapper = document.querySelector('.table-header-wrapper');
    bodyWrapper = document.querySelector('.table-body-wrapper');
}

function updateSortVisuals() {
    document.querySelectorAll('#header-table thead th').forEach(th => {
        th.classList.remove('sort-asc', 'sort-desc');
    });
    const header = document.querySelector<HTMLTableCellElement>(`#header-table thead th[data-sort-by="${sortState.column}"]`);
    if (header) {
        header.classList.add(sortState.order === 'asc' ? 'sort-asc' : 'sort-desc');
    }
}

async function handleRowClick(row: HTMLTableRowElement, lib: LibraryInfo) {
    document.querySelectorAll('#body-table tbody tr').forEach(r => r.classList.remove('selected'));
    row.classList.add('selected');

    if (!infoHeader || !tabContent || !infoPlaceholder) return;

    infoPlaceholder.style.display = 'none';
    infoHeader.style.display = 'block';
    if (tabNav) {
        tabNav.style.display = 'flex';
    }
    tabContent.style.display = 'block';

    infoHeader.textContent = lib.name;
    
    // 显示和配置 Fix 按钮
    const fixBtn = document.getElementById('fix-btn') as HTMLButtonElement;
    if (fixBtn) {
        fixBtn.style.display = 'flex';
        fixBtn.className = 'fix-btn';
        
        // 根据注册状态设置按钮样式
        if (lib.registration_status === '0/3') {
            fixBtn.classList.add('error');
        } else if (lib.registration_status !== '3/3') {
            fixBtn.classList.add('warning');
        }
        
        // 添加点击事件
        fixBtn.onclick = () => {
            console.log(`尝试修复音色库: ${lib.name}`);
            // TODO: 实现修复功能
        };
    }

    document.querySelectorAll('.tab-pane').forEach(pane => {
        (pane as HTMLElement).innerHTML = '<p>正在加载...</p>';
    });

    try {
        const details = await invoke<LibraryDetails>('get_library_details', { name: lib.name });
        
        const overviewTab = document.getElementById('tab-overview');
        if (overviewTab) {
            // 重新构建概览界面的HTML结构
            overviewTab.innerHTML = `
                <div class="overview-image-container">
                    <div class="image-placeholder">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round">
                            <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                            <circle cx="8.5" cy="8.5" r="1.5"></circle>
                            <polyline points="21,15 16,10 5,21"></polyline>
                        </svg>
                        <span>暂无图片</span>
                    </div>
                </div>
                <div class="overview-separator"></div>
                <div class="overview-path-container">
                    <div id="library-path" class="library-path"></div>
                </div>
            `;
            
            // 设置路径内容
            const pathElement = document.getElementById('library-path');
            if (pathElement && details.content_dir) {
                pathElement.textContent = details.content_dir;
                pathElement.title = details.content_dir;
                
                // 检查路径长度，添加长路径类
                if (details.content_dir.length > 50) {
                    pathElement.classList.add('long-path');
                }
                
                // 添加点击打开文件夹功能
                pathElement.addEventListener('click', () => {
                    open(details.content_dir as string);
                });
            } else if (pathElement) {
                pathElement.textContent = '未找到该库的文件目录信息';
                pathElement.style.color = 'var(--text-muted)';
                pathElement.style.fontStyle = 'italic';
            }
        }

        const registrationTab = document.getElementById('tab-registration');
        if (registrationTab) {
            registrationTab.innerHTML = '';
            if (details.paths.length > 0) {
                const table = document.createElement('table');
                details.paths.forEach(path => {
                    const row = table.insertRow();
                    row.insertCell(0).textContent = path;
                });
                registrationTab.appendChild(table);
            } else {
                registrationTab.innerHTML = '<p>在任何位置都未找到该库的注册信息。</p>';
            }
        }

    } catch (error) {
        console.error("Failed to get library details:", error);
        document.querySelectorAll('.tab-pane').forEach(pane => {
            (pane as HTMLElement).innerHTML = '<p style="color: red;">获取详细信息失败。</p>';
        });
    }
}

function sortAndRender() {
    currentLibraries.sort((a, b) => {
        const valA = a[sortState.column as keyof LibraryInfo].toLowerCase();
        const valB = b[sortState.column as keyof LibraryInfo].toLowerCase();
        let comparison = valA.localeCompare(valB, 'en');
        return sortState.order === 'asc' ? comparison : -comparison;
    });

    if (!bodyTableBody) return;
    bodyTableBody.innerHTML = ''; 
    currentLibraries.forEach(lib => {
        const row = bodyTableBody.insertRow();
        row.addEventListener('click', () => handleRowClick(row, lib));
        
        row.insertCell(0).textContent = lib.name;
        row.insertCell(1).textContent = lib.library_type;
        
        const statusCell = row.insertCell(2);
        const statusIndicator = document.createElement('span');
        statusIndicator.className = `status-indicator ${lib.registration_status === '3/3' ? 'green' : 'red'}`;
        statusCell.textContent = lib.registration_status;
        statusCell.appendChild(statusIndicator);
    });
    updateSortVisuals();
}

async function loadLibraries() {
    try {
        const result = await invoke<LibraryQueryResult>('get_installed_libraries');
        currentLibraries = result.libraries; 
        sortAndRender(); 

        if (summaryElement) {
            summaryElement.textContent = `共${result.total_count}个音色库 | ${result.standard_count}个标准库 | ${result.custom_count}个自定义库`;
        }
    } catch (error) {
        console.error('Failed to load libraries:', error);
        if (summaryElement) {
            summaryElement.textContent = '加载音色库失败';
        }
    }
}

function setupTabListeners() {
    const tabButtons = document.querySelectorAll<HTMLButtonElement>('.tab-btn');
    
    tabButtons.forEach(button => {
        button.addEventListener('click', () => {
            const tabId = button.dataset.tab;
            tabButtons.forEach(btn => btn.classList.remove('active'));
            button.classList.add('active');
            document.querySelectorAll<HTMLElement>('.tab-pane').forEach(pane => {
                pane.classList.remove('active');
                if (pane.id === `tab-${tabId}`) {
                    pane.classList.add('active');
                }
            });
        });
    });

    const tabNav = document.querySelector<HTMLElement>('.tab-nav');
    if (tabNav) {
        tabNav.addEventListener('wheel', (e) => {
            e.preventDefault();
            const buttons = Array.from(tabButtons);
            const currentIndex = buttons.findIndex(btn => btn.classList.contains('active'));
            let nextIndex = currentIndex;
            if (e.deltaY > 0) {
                if (currentIndex < buttons.length - 1) nextIndex = currentIndex + 1;
            } else {
                if (currentIndex > 0) nextIndex = currentIndex - 1;
            }
            if (nextIndex !== currentIndex) buttons[nextIndex].click();
        });
    }
}

window.addEventListener('DOMContentLoaded', () => {
  initializeDOMElements();

  if(infoHeader && infoPlaceholder && tabNav && tabContent) {
      infoHeader.style.display = 'none';
      tabNav.style.display = 'none';
      tabContent.style.display = 'none';
  }
  
  // 初始时隐藏Fix按钮
  const fixBtn = document.getElementById('fix-btn');
  if (fixBtn) {
      fixBtn.style.display = 'none';
  }
  
  const closeBtn = document.getElementById('close-btn');
  if (closeBtn) closeBtn.addEventListener('click', () => WebviewWindow.getCurrent().hide());

  const settingsBtn = document.getElementById('settings-btn');
  if (settingsBtn) settingsBtn.addEventListener('click', () => console.log('Settings button clicked'));

  document.querySelectorAll<HTMLTableCellElement>('#header-table thead th').forEach(header => {
      header.addEventListener('click', () => {
          const sortBy = header.dataset.sortBy;
          if (!sortBy) return;
          if (sortState.column === sortBy) {
              sortState.order = sortState.order === 'asc' ? 'desc' : 'asc';
          } else {
              sortState.column = sortBy;
              sortState.order = 'asc';
          }
          sortAndRender();
      });
  });
  
  setupTabListeners();
  loadLibraries();

  // --- Scroll Synchronization Logic ---
  if (headerWrapper && bodyWrapper) {
      headerWrapper.addEventListener('scroll', () => {
          bodyWrapper.scrollLeft = headerWrapper.scrollLeft;
      });
      bodyWrapper.addEventListener('scroll', () => {
          headerWrapper.scrollLeft = bodyWrapper.scrollLeft;
      });
  }
});
