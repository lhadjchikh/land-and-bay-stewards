/**
 * Utilities Module
 * 
 * Shared functions for HTTP requests, service checking, and testing
 */

const http = require('http');
const https = require('https');
const { URL } = require('url');

/**
 * Makes an HTTP request to the specified URL
 * 
 * @param {string} url - The URL to request
 * @param {object} options - Request options
 * @returns {Promise<object>} Response object
 */
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    try {
      // Parse the URL to get the protocol
      const parsedUrl = new URL(url);
      const httpModule = parsedUrl.protocol === 'https:' ? https : http;
      
      const requestOptions = {
        method: options.method || 'GET',
        headers: options.headers || {},
        timeout: options.timeout || 30000
      };
      
      const req = httpModule.get(url, requestOptions, (response) => {
        let data = '';
        
        // Handle data chunks
        response.on('data', (chunk) => {
          data += chunk;
        });
        
        // Handle end of response
        response.on('end', () => {
          try {
            resolve({
              statusCode: response.statusCode,
              data: data,
              headers: response.headers,
            });
          } catch (error) {
            reject(new Error(`Failed to process response: ${error.message}`));
          }
        });
      });

      // Handle request errors
      req.on('error', (error) => {
        reject(new Error(`Request failed: ${error.message}`));
      });

      // Handle timeout
      req.on('timeout', () => {
        req.destroy();
        reject(new Error(`Request timeout after ${requestOptions.timeout}ms`));
      });
    } catch (error) {
      reject(new Error(`Failed to make request: ${error.message}`));
    }
  });
}

/**
 * Waits for a service to be ready, with exponential backoff
 * 
 * @param {string} url - The URL to check
 * @param {number} maxAttempts - Maximum number of attempts
 * @param {number} timeout - Maximum time to wait in ms
 * @returns {Promise<boolean>} True if service is ready
 */
async function waitForService(url, { 
  maxAttempts = 30, 
  timeout = 60000,
  initialDelay = 1000,
  maxDelay = 8000 
} = {}) {
  console.log(`Waiting for service at ${url}...`);
  
  const startTime = Date.now();
  let retryDelay = initialDelay;
  let attempts = 0;
  
  while (Date.now() - startTime < timeout && attempts < maxAttempts) {
    attempts++;
    try {
      const response = await makeRequest(url);
      if (response.statusCode === 200) {
        console.log(`✅ Service at ${url} is ready`);
        return true;
      } else {
        console.log(`⚠️ Service at ${url} returned status ${response.statusCode}, waiting...`);
      }
    } catch (error) {
      console.log(`⚠️ Service not ready: ${error.message}`);
    }

    if (attempts >= maxAttempts || Date.now() + retryDelay > startTime + timeout) {
      break;
    }
    
    console.log(`Waiting for ${url}... (${attempts}/${maxAttempts})`);
    
    // Exponential backoff with jitter
    const jitter = Math.random() * 500;
    retryDelay = Math.min(retryDelay * 1.5 + jitter, maxDelay);
    
    await new Promise((resolve) => setTimeout(resolve, retryDelay));
  }

  throw new Error(
    `Service at ${url} not ready after ${attempts} attempts or ${Date.now() - startTime}ms`
  );
}

/**
 * A fetch-like wrapper around makeRequest for compatibility
 * 
 * @param {string} url - The URL to fetch
 * @param {object} options - Fetch options
 * @returns {Promise<object>} Fetch-like response object
 */
async function fetchCompatible(url, options = {}) {
  try {
    const response = await makeRequest(url, options);
    return {
      ok: response.statusCode >= 200 && response.statusCode < 300,
      status: response.statusCode,
      statusText: response.statusCode === 200 ? 'OK' : 'Error',
      headers: response.headers,
      url: url,
      json: () => JSON.parse(response.data),
      text: () => response.data
    };
  } catch (error) {
    console.error(`Fetch error: ${error.message}`);
    throw error;
  }
}

/**
 * Make HTTP requests with retries and exponential backoff
 * 
 * @param {string} url - URL to fetch
 * @param {object} options - Fetch options
 * @param {object} retryOptions - Retry configuration
 * @returns {Promise<object>} Fetch response
 */
async function fetchWithRetry(url, options = {}, { 
  retryCount = 5, 
  initialDelay = 3000,
  maxDelay = 10000
} = {}) {
  let retryDelay = initialDelay;

  for (let i = 0; i < retryCount; i++) {
    try {
      return await fetchCompatible(url, options);
    } catch (error) {
      if (i === retryCount - 1) {
        throw error;
      }
      
      console.log(
        `Request failed (attempt ${i + 1}/${retryCount}): ${error.message}, retrying...`
      );
      
      // Exponential backoff with jitter
      const jitter = Math.random() * 500;
      retryDelay = Math.min(retryDelay * 1.5 + jitter, maxDelay);
      
      await new Promise((resolve) => setTimeout(resolve, retryDelay));
    }
  }
  
  throw new Error(`Failed after ${retryCount} attempts`);
}

module.exports = {
  makeRequest,
  waitForService,
  fetchCompatible,
  fetchWithRetry
};