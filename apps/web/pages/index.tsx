// apps/web/pages/index.tsx

import type { NextPage } from 'next';
import Head from 'next/head';

const HomePage: NextPage = () => {
  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      height: '100vh',
      fontFamily: 'sans-serif',
      backgroundColor: '#f0f0f0'
    }}>
      <Head>
        <title>Kivixa</title>
      </Head>
      <main>
        <h1>Kivixa backend ready</h1>
        <p>The Next.js server is running and can connect to the core backend.</p>
      </main>
    </div>
  );
};

export default HomePage;
