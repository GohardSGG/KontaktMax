import { WebviewWindow } from '@tauri-apps/api/webviewWindow';
import { invoke } from '@tauri-apps/api/core';

interface LibraryInfo {
    name: string;
    library_type: string;
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
    column: 'name', // Default sort column
    order: 'asc'    // Default sort order
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

function sortAndRender() {
    // Sort the libraries based on the current sort state
    currentLibraries.sort((a, b) => {
        const valA = a[sortState.column as keyof LibraryInfo].toLowerCase();
        const valB = b[sortState.column as keyof LibraryInfo].toLowerCase();

        let comparison = valA.localeCompare(valB, 'en'); // Use localeCompare for better string sorting
        
        return sortState.order === 'asc' ? comparison : -comparison;
    });

    // --- Render Table ---
    const tableBody = document.querySelector<HTMLTableSectionElement>('#library-table tbody');
    if (!tableBody) return;

    tableBody.innerHTML = ''; // Clear existing rows
    currentLibraries.forEach(lib => {
        const row = tableBody.insertRow();
        const nameCell = row.insertCell(0);
        nameCell.textContent = lib.name;
        const typeCell = row.insertCell(1);
        typeCell.textContent = lib.library_type;
    });

    updateSortVisuals();
}

async function loadLibraries() {
    try {
        const result = await invoke<LibraryQueryResult>('get_installed_libraries');
        
        currentLibraries = result.libraries; // Store the original data
        sortAndRender(); // Sort and render for the first time

        // --- Render Summary ---
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
  // --- Window Controls ---
  const closeBtn = document.getElementById('close-btn');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => WebviewWindow.getCurrent().hide());
  }

  const settingsBtn = document.getElementById('settings-btn');
  if (settingsBtn) {
    settingsBtn.addEventListener('click', () => console.log('Settings button clicked'));
  }

  // --- Sorting Event Listeners ---
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
  
  // --- Initial Load ---
  loadLibraries();
});
