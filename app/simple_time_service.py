# Import dependencies
from datetime import datetime
from fastapi import FastAPI, Request

# Create a FastAPI instancce
app = FastAPI()

# Define a route that returns the current time and the IP address of the caller
@app.get('/')
async def get_time_and_ip(request: Request):
    current_time = datetime.now().isoformat()
    caller_ip = request.client.host
    return {'timestamp': current_time, 'ip': caller_ip}

# Run the FastAPI app with Uvicorn (port is hardcoded to 8000 for simple deployment)
if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)