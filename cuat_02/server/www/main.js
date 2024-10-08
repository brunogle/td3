async function send_lcd_update() {
    const textarea = document.getElementById('textbox');
    const text = textarea.value;
    const payload = JSON.stringify({ text: text });

    try {
        console.log("Payload:" + payload);
        const response = await fetch('/update_lcd', {
            method: 'POST', // or 'GET', depending on your server
            headers: {
                'Content-Type': 'application/json',
            },
            body: payload,
        })
        
        if (!response.ok) {
            //alert('Failed to send text.');
            throw new Error(`Response status: ${response.status}`);
        }
    }
    catch (error) {
        alert('Failed to send text.');
        console.error(error.message);
    }

}
function limitTextArea(textarea) {
    /*
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
    }*/
        const lines = textarea.value.split("\n");
        let modifiedText = "";

        // Process each line
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            
            // If a line exceeds 16 characters, break it into a new line
            if (line.length > 16) {
                modifiedText += line.slice(0, 16) + "\n" + line.slice(16);
            } else {
                modifiedText += line;
            }

            // Add a newline between rows except for the last row
            if (i < lines.length - 1) {
                modifiedText += "\n";
            }
        }

        // Limit the total number of rows to 4
        const resultLines = modifiedText.split("\n").slice(0, 4);
        textarea.value = resultLines.join("\n");
}