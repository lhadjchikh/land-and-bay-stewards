import React from 'react';
import logo from './logo.svg';
import './App.css';
import CampaignsList from './components/CampaignsList';

const App: React.FC = () => {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <h1>{process.env.REACT_APP_ORGANIZATION_NAME || 'Coalition Builder'}</h1>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
      <main className="App-main">
        <CampaignsList />
      </main>
    </div>
  );
};

export default App;
