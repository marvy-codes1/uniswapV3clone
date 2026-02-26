import './App.css';
import { useState } from 'react';
import SwapForm from './components/SwapForm.js';
import MetaMask from './components/MetaMask.js';
import EventsFeed from './components/EventsFeed.js';
import Footer from './components/Footer.js';
import { MetaMaskProvider } from './contexts/MetaMask';

const App = () => {
  const [pairs, setPairs] = useState([]);

  return (
    <MetaMaskProvider>
      <div className="App flex flex-col justify-between items-center w-full h-full">
        <header className="app-header">
          <h1 className="app-title">
            <span className="gradient-text">Uniswap V3</span> Clone
          </h1>
          <MetaMask />
        </header>
        <main className="app-main">
          <SwapForm setPairs={setPairs} />
          <EventsFeed pairs={pairs} />
        </main>
        <Footer />
      </div>
    </MetaMaskProvider>
  );
}

export default App;
