function timeoutError(label, timeoutMs) {
  const error = new Error(`${label} timed out after ${timeoutMs}ms`);
  error.code = "ETIMEDOUT";
  return error;
}

async function withTimeout(operation, { label, timeoutMs }) {
  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(timeoutError(label, timeoutMs)), timeoutMs);
  });

  return Promise.race([operation(), timeoutPromise]);
}

async function invokeWithPolicy({
  label,
  operation,
  fallbackValue,
  retries = 1,
  timeoutMs = 4000,
}) {
  const maxAttempts = Math.max(1, retries + 1);
  let lastError = null;

  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    try {
      const result = await withTimeout(operation, { label, timeoutMs });
      return {
        result,
        degraded: false,
        attempts: attempt,
        error: null,
      };
    } catch (error) {
      lastError = error;
    }
  }

  return {
    result: fallbackValue,
    degraded: true,
    attempts: maxAttempts,
    error: lastError,
  };
}

module.exports = {
  invokeWithPolicy,
};
