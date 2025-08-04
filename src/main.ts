import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import { invoke } from '@tauri-apps/api/core';

interface LibraryInfo {
    name: string;
    library_type: string;
    registration_status: string;
}

interface LibraryDetails {
    name: string;
    paths: string[];
}

interface LibraryQueryResult {
    libraries: LibraryInfo[];
    total_count: number;
    standard_count: number;
    custom_count: number;
}

// --- Global State for Sorting ---
let currentLibraries: LibraryInfo[] = [];
let sortState = {
    column: 'name',
    order: 'asc'
};

function updateSortVisuals() {
    document.querySelectorAll('#library-table thead th').forEach(th => {
        th.classList.remove('sort-asc', 'sort-desc');
    });

    const header = document.querySelector<HTMLTableCellElement>(`#library-table thead th[data-sort-by="${sortState.column}"]`);
    if (header) {
        header.classList.add(sortState.order === 'asc' ? 'sort-asc' : 'sort-desc');
    }
}

async function handleRowClick(row: HTMLTableRowElement, lib: LibraryInfo) {
    // Highlight clicked row
    document.querySelectorAll('#library-table tbody tr').forEach(r => r.classList.remove('selected'));
    row.classList.add('selected');

    const infoDetails = document.getElementById('info-details');
    if (!infoDetails) return;

    infoDetails.innerHTML = '<p>正在加载详细信息...</p>';

    try {
        const details = await invoke<LibraryDetails>('get_library_details', { name: lib.name });
        
        infoDetails.innerHTML = `<strong>${details.name}</strong>`;
        if (details.paths.length > 0) {
            details.paths.forEach(path => {
                const p = document.createElement('p');
                p.textContent = path;
                infoDetails.appendChild(p);
            });
        } else {
            const p = document.createElement('p');
            p.textContent = '在任何位置都未找到该库的注册信息。';
            infoDetails.appendChild(p);
        }

    } catch (error) {
        infoDetails.innerHTML = '<p style="color: red;">获取详细信息失败。</p>';
        console.error("Failed to get library details:", error);
    }
}

function sortAndRender() {
    currentLibraries.sort((a, b) => {
        const valA = a[sortState.column as keyof LibraryInfo].toLowerCase();
        const valB = b[sortState.column as keyof LibraryInfo].toLowerCase();
        let comparison = valA.localeCompare(valB, 'en');
        return sortState.order === 'asc' ? comparison : -comparison;
    });

    const tableBody = document.querySelector<HTMLTableSectionElement>('#library-table tbody');
    if (!tableBody) return;

    tableBody.innerHTML = ''; 
    currentLibraries.forEach(lib => {
        const row = tableBody.insertRow();
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

        const summaryElement = document.getElementById('library-summary');
        if (summaryElement) {
            summaryElement.textContent = `共${result.total_count}个音色库 | ${result.standard_count}个标准库 | ${result.custom_count}个自定义库`;
        }
    } catch (error) {
        console.error('Failed to load libraries:', error);
        const summaryElement = document.getElementById('library-summary');
        if (summaryElement) {
            summaryElement.textContent = '加载音色库失败';
        }
    }
}

window.addEventListener('DOMContentLoaded', () => {
  const closeBtn = document.getElementById('close-btn');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => WebviewWindow.getCurrent().hide());
  }

  const settingsBtn = document.getElementById('settings-btn');
  if (settingsBtn) {
    settingsBtn.addEventListener('click', () => console.log('Settings button clicked'));
  }

  document.querySelectorAll<HTMLTableCellElement>('#library-table thead th').forEach(header => {
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
  
  loadLibraries();
});
