// WWWorkRemote Content Script
// Listens for the ?wwr_id=NNN parameter and injects the enrichment overlay

(function() {
  const urlParams = new URLSearchParams(window.location.search);
  const wwrId = urlParams.get('wwr_id');

  if (wwrId) {
    console.log("🚀 WWWorkRemote Enrichment Mode Active for ID:", wwrId);
    injectOverlay(wwrId);
  }

  function injectOverlay(id) {
    const div = document.createElement('div');
    div.id = 'wwr-enrichment-overlay';
    div.style.position = 'fixed';
    div.style.top = '20px';
    div.style.right = '20px';
    div.style.zIndex = '999999';
    div.style.background = '#282a36'; // Dracula Background
    div.style.color = '#f8f8f2';
    div.style.padding = '15px';
    div.style.borderRadius = '8px';
    div.style.boxShadow = '0 10px 30px rgba(0,0,0,0.5)';
    div.style.border = '2px solid #bd93f9'; // Dracula Purple
    div.style.fontFamily = 'monospace';
    div.style.fontSize = '12px';
    div.style.width = '250px';

    div.innerHTML = `
      <div style="font-weight: black; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 1px; color: #ff79c6;">Synthesis_Link Active</div>
      <div style="margin-bottom: 15px; color: #6272a4;">Target ID: <span style="color: #50fa7b;">#${id}</span></div>
      <button id="wwr-capture-btn" style="width: 100%; padding: 10px; background: #50fa7b; color: #282a36; border: none; border-radius: 4px; font-weight: bold; cursor: pointer; margin-bottom: 10px;">CAPTURE & SYNC</button>
      <div id="wwr-status" style="text-align: center; font-size: 10px; color: #6272a4;">Waiting for user...</div>
    `;

    document.body.appendChild(div);

    document.getElementById('wwr-capture-btn').addEventListener('click', () => {
      captureAndSync(id);
    });
  }

  async function captureAndSync(id) {
    const status = document.getElementById('wwr-status');
    status.innerText = "🔄 Extracting DOM...";
    status.style.color = "#f1fa8c";

    // Grab the core content
    const payload = {
      id: id,
      html: document.body.innerHTML,
      url: window.location.href,
      title: document.title
    };

    status.innerText = "📤 Syncing to Core...";

    try {
      const response = await fetch(`http://localhost:3010/api/job_postings/${id}/enrich`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        status.innerText = "✨ SYNC COMPLETE";
        status.style.color = "#50fa7b";
        setTimeout(() => {
          document.getElementById('wwr-enrichment-overlay').remove();
        }, 2000);
      } else {
        throw new Error(`API Error: ${response.status}`);
      }
    } catch (err) {
      status.innerText = `❌ FAIL: ${err.message}`;
      status.style.color = "#ff5555";
      console.error("[WWWR] Capture failed", err);
    }
  }
})();
