import React, { createContext, useContext, useEffect, useState } from 'react';

const WebSocketContext = createContext(null);

export const WebSocketProvider = ({ children }) => {
  const [socket, setSocket] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [centers, setCenters] = useState([]);
  const [dispatches, setDispatches] = useState([]);
  const [latestAlert, setLatestAlert] = useState(null);

  const fetchInitialData = async () => {
    try {
      const [resCenters, resTasks] = await Promise.all([
        fetch('/api/centers/'),
        fetch('/api/audit-tasks/')
      ]);
      if (resCenters.ok) {
        const data = await resCenters.json();
        setCenters(data.results || data);
      }
      if (resTasks.ok) {
        const data = await resTasks.json();
        setDispatches(data.results || data);
      }
    } catch (e) {
      console.warn("API fetch error:", e);
    }
  };

  useEffect(() => {
    fetchInitialData();

    const wsProtocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
    const wsHost = window.location.port === '3000' ? '127.0.0.1:8000' : window.location.host;
    const wsUrl = `${wsProtocol}//${wsHost}/ws/dashboard/`;
    
    let ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      setIsConnected(true);
      setSocket(ws);
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        if (data.event_type === 'HEADCOUNT_UPDATE') {
          const payload = data.data;
          
          // Update center state
          setCenters(prev => prev.map(c => {
            if (c.code === payload.center_code || c.id === payload.center_id) {
              return {
                ...c,
                current_headcount: payload.current_headcount,
                risk_score: payload.risk_score,
                risk_level: payload.risk_level,
                latest_snapshot: payload.snapshot_url
              };
            }
            return c;
          }));

          // Trigger Alert notification if unannounced dispatch generated
          if (payload.unannounced_dispatch_triggered) {
            setLatestAlert({
              id: Date.now(),
              center_name: payload.center_name,
              task_id: payload.dispatch_task_id,
              risk_score: payload.risk_score,
              timestamp: new Date().toLocaleTimeString()
            });

            // Refresh tasks list
            fetchInitialData();
          }
        }
      } catch (err) {
        console.error("Error parsing WS message", err);
      }
    };

    ws.onclose = () => {
      setIsConnected(false);
    };

    return () => {
      ws.close();
    };
  }, []);

  const triggerSampleAI = async () => {
    try {
      const res = await fetch('/api/ai/trigger/', { method: 'POST' });
      if (res.ok) {
        fetchInitialData();
      }
    } catch (err) {
      console.error(err);
    }
  };

  return (
    <WebSocketContext.Provider value={{
      isConnected,
      centers,
      dispatches,
      latestAlert,
      refreshData: fetchInitialData,
      triggerSampleAI
    }}>
      {children}
    </WebSocketContext.Provider>
  );
};

export const useWebSocket = () => useContext(WebSocketContext);
