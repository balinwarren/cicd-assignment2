function fetchMOTD() {
    fetch('http://127.0.0.1:5000/motd')  // Replace this URL with your backend endpoint
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            // Set the fetched MOTD in the <p> tag
            document.getElementById('motd').innerText = data.motd;
        })
        .catch(error => {
            console.error('There was a problem with the fetch operation:', error);
            document.getElementById('motd').innerText = 'Error loading MOTD.';
        });
}

// Call the function to fetch the MOTD when the page loads
window.onload = fetchMOTD;