import { createRoot } from "react-dom/client";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import "./style.css";
import Config from "./components/Config";
import DropZone from "./components/DropZone";

const queryClient = new QueryClient();

const App: React.FC = () => (
  <QueryClientProvider client={queryClient}>
    <Config>
      <main>
        <h1>imgr.</h1>
        <DropZone />
      </main>
    </Config>
  </QueryClientProvider>
);

const container = document.getElementById("root");
if (!container) throw new Error("No root element found");

const root = createRoot(container);
root.render(<App />);
