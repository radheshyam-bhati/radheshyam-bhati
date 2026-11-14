const fs = require("fs");
const fetch = require("node-fetch");

const USERNAME = process.env.USERNAME || "radheshyam-bhati";
const TOKEN = process.env.GITHUB_TOKEN;

const headers = {
  Authorization: `Bearer ${TOKEN}`,
  "User-Agent": "living-profile",
  Accept: "application/vnd.github+json",
};

async function graphql(query) {
  const res = await fetch("https://api.github.com/graphql", {
    method: "POST",
    headers: { ...headers, "Content-Type": "application/json" },
    body: JSON.stringify({ query }),
  });
  const json = await res.json();
  if (json.errors) throw new Error(JSON.stringify(json.errors, null, 2));
  return json.data;
}

async function getProjects() {
  const data = await graphql(`
    {
      user(login: "${USERNAME}") {
        pinnedItems(first: 6, types: REPOSITORY) {
          nodes {
            ... on Repository {
              name
              description
              url
              isFork
              primaryLanguage { name }
              repositoryTopics(first: 8) {
                nodes { topic { name } }
              }
              stargazerCount
              updatedAt
              owner { login }
            }
          }
        }
        repositories(
          first: 30
          orderBy: { field: UPDATED_AT, direction: DESC }
          privacy: PUBLIC
          ownerAffiliations: OWNER
        ) {
          nodes {
            name
            description
            url
            isFork
            primaryLanguage { name }
            repositoryTopics(first: 8) {
              nodes { topic { name } }
            }
            stargazerCount
            updatedAt
            owner { login }
          }
        }
      }
    }
  `);

  const pinned = (data.user.pinnedItems.nodes || []).filter(
    (r) => r && !r.isFork && r.owner?.login === USERNAME
  );

  const recent = (data.user.repositories.nodes || []).filter(
    (r) =>
      r &&
      !r.isFork &&
      r.owner?.login === USERNAME &&
      !pinned.some((p) => p.name === r.name)
  );

  // Prefer repos that actually have a description
  const withDescription = [...pinned, ...recent].filter(
    (r) => r.description && r.description.trim().length > 10
  );
  const withoutDescription = [...pinned, ...recent].filter(
    (r) => !r.description || r.description.trim().length <= 10
  );

  // Final order: pinned with desc → recent with desc → others (max 6)
  const selected = [...withDescription, ...withoutDescription].slice(0, 6);
  return selected;
}

async function getLanguages() {
  const res = await fetch(
    `https://api.github.com/users/${USERNAME}/repos?per_page=100&type=owner&sort=updated`,
    { headers }
  );
  const repos = await res.json();

  const langCount = {};
  for (const repo of repos) {
    if (repo.fork || !repo.language) continue;
    langCount[repo.language] = (langCount[repo.language] || 0) + 1;
  }

  const map = {
    TypeScript: "typescript",
    JavaScript: "js",
    Python: "python",
    HTML: "html",
    CSS: "css",
    "C++": "cpp",
    C: "c",
    Java: "java",
    Go: "go",
    Rust: "rust",
    Shell: "bash",
    Dockerfile: "docker",
    Vue: "vue",
    React: "react",
  };

  const icons = Object.entries(langCount)
    .sort((a, b) => b[1] - a[1])
    .map(([lang]) => map[lang])
    .filter(Boolean);

  // Keep a strong core + detected languages
  const core = ["typescript", "react", "nextjs", "nodejs", "python", "postgres", "redis", "docker"];
  const final = [...new Set([...core, ...icons])].slice(0, 12);
  return final.join(",");
}

function getCategory(repo) {
  const topics = (repo.repositoryTopics?.nodes || []).map((t) => t.topic.name.toLowerCase());
  const lang = (repo.primaryLanguage?.name || "").toLowerCase();

  if (topics.includes("ai") || topics.includes("ml") || topics.includes("rag")) return "AI · ML";
  if (topics.includes("realtime") || topics.includes("websocket") || topics.includes("game")) return "Real-time";
  if (topics.includes("healthcare") || topics.includes("medical")) return "Healthcare";
  if (topics.includes("featured") || topics.includes("portfolio")) return "Featured";
  if (lang === "typescript" || lang === "javascript") return "Web";
  if (lang === "python") return "Python";
  return lang ? lang.charAt(0).toUpperCase() + lang.slice(1) : "Project";
}

function cleanDescription(desc, name) {
  if (desc && desc.trim().length > 15) {
    return desc.trim().length > 95 ? desc.trim().slice(0, 92) + "…" : desc.trim();
  }
  // Friendly fallback instead of "No description"
  return `Personal project · ${name.replace(/-/g, " ")}`;
}

function makeCard(repo, accent) {
  const category = getCategory(repo);
  const desc = cleanDescription(repo.description, repo.name);
  const lang = repo.primaryLanguage?.name || "Code";

  return `
<td width="50%" valign="top">
  <a href="${repo.url}" style="text-decoration:none;color:inherit;">
    <div style="border:1px solid #e2e8f0;border-radius:16px;padding:22px 24px;margin:6px;background:#ffffff;">
      <p style="font-size:11px;font-weight:600;letter-spacing:1px;text-transform:uppercase;color:${accent};margin:0 0 8px;">${category}</p>
      <h3 style="font-size:17px;font-weight:700;color:#0f172a;margin:0 0 8px;">${repo.name}</h3>
      <p style="font-size:13px;color:#64748b;line-height:1.5;margin:0 0 14px;">${desc}</p>
      <p style="margin:0;"><code style="font-size:11px;background:#f1f5f9;padding:3px 8px;border-radius:6px;color:#475569;">${lang}</code></p>
    </div>
  </a>
</td>`.trim();
}

async function main() {
  const repos = await getProjects();
  const languages = await getLanguages();

  const accents = ["#667eea", "#10b981", "#f97316", "#8b5cf6", "#ec4899", "#06b6d4"];

  let projectsHtml = "<table>\n";
  for (let i = 0; i < repos.length; i += 2) {
    projectsHtml += "  <tr>\n";
    projectsHtml += "    " + makeCard(repos[i], accents[i % accents.length]) + "\n";
    if (repos[i + 1]) {
      projectsHtml += "    " + makeCard(repos[i + 1], accents[(i + 1) % accents.length]) + "\n";
    } else {
      // keep layout balanced if odd number
      projectsHtml += `    <td width="50%"></td>\n`;
    }
    projectsHtml += "  </tr>\n";
  }
  projectsHtml += "</table>";

  const techHtml = `
<div align="center">
  <p style="font-size: 0.75rem; letter-spacing: 0.15em; text-transform: uppercase; color: #94a3b8; font-weight: 600; margin-bottom: 14px;">
    Tech Stack · Auto-detected
  </p>
  <img src="https://skillicons.dev/icons?i=${languages}" height="42" alt="Tech Stack"/>
</div>`.trim();

  let readme = fs.readFileSync("README.md", "utf8");

  readme = readme.replace(
    /<!--TECH-STACK-START-->[\s\S]*?<!--TECH-STACK-END-->/,
    `<!--TECH-STACK-START-->\n${techHtml}\n<!--TECH-STACK-END-->`
  );

  readme = readme.replace(
    /<!--PROJECTS-START-->[\s\S]*?<!--PROJECTS-END-->/,
    `<!--PROJECTS-START-->\n${projectsHtml}\n<!--PROJECTS-END-->`
  );

  fs.writeFileSync("README.md", readme);
  console.log(`Updated with ${repos.length} projects`);
  console.log(repos.map((r) => r.name).join(", "));
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
