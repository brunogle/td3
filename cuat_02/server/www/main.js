async function send_lcd_update() {
    const textarea = document.getElementById('textbox');
    const text = textarea.value;
    const payload = JSON.stringify({ text: text });

    try {
        console.log("Payload:" + payload);
        const response = await fetch('/ajax_update_lcd', {
            method: 'POST', // or 'GET', depending on your server
            headers: {
                'Content-Type': 'application/json',
            },
            body: payload,
        })
        
        if (!response.ok) {
            alert('Failed to send text.');
            throw new Error(`Response status: ${response.status}`);
        }
    }
    catch (error) {
        console.error(error.message);
    }

}
function limitTextArea(textarea) {

    const lines = textarea.value.split("\n");
    const maxLines = 4;
    const maxCharsPerLine = 16;
    let truncated = "";

    for (let i = 0; i < lines.length && i < maxLines; i++) {
        if (lines[i].length > maxCharsPerLine) {
            truncated += lines[i].slice(0, maxCharsPerLine) + "\n";
        } else {
            truncated += lines[i] + "\n";
        }
    }

    if (truncated !== textarea.value) {
        textarea.value = truncated.slice(0, -1); // Remove the last new line
    }

}