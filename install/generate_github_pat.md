# ⭐ **How to Generate a GitHub Personal Access Token (PAT)**

## ✅ **Step 1 — Log in to GitHub**

Go to:

🔗 [https://github.com/login](https://github.com/login)

---

## ✅ **Step 2 — Go to Developer Settings**

In the top-right corner → click your profile photo → **Settings**

Then, on the left sidebar, scroll to the bottom:

**Developer settings → Personal access tokens → Tokens (classic)**
or
**Developer settings → Fine-grained tokens** (recommended)

---

# ⭐ OPTION A — Fine-Grained Token (Recommended)

## Step: Create a new fine-grained token

Click:

➡️ **Fine-grained tokens**
➡️ **Generate new token**

---

### 1. **Name your token**

Example:

```
clone-all-repos-token
```

### 2. **Expiration**

Choose:

* 30 days
* 90 days
* Or **no expiration** (only if you trust your device)

### 3. **Select Resource Owner**

Choose **your personal account**.

### 4. **Repository Access**

Pick either:

* **All Repositories**
  **or**
* **Only selected repositories**

If you want to clone ALL repos → choose **All Repositories**.

### 5. **Permissions**

Check:

#### ✔ **Repository permissions**

* **Contents → Read/Write** (or at least **Read** if cloning only)
* Metadata → Read
* Issues (optional)

For cloning only:

```
Contents: Read
Metadata: Read
```

---

### 6. Click **Generate Token**

You’ll now see the token **once only**.
Copy it and save it somewhere secure.

---

# ⭐ OPTION B — Classic Token (Older but still works)

Go to:

Developer Settings → **Personal Access Tokens → Tokens (Classic)** → **Generate new token**

Check at least:

### ✔ Scopes needed for cloning private repos:

* `repo` (this covers everything you need)

Then click **Generate Token**.

Copy the token.

---

# ⭐ **How to use the token to clone repos**

### **Option 1: Use HTTPS + token**

When Git asks for username/password:

* Username: your GitHub username
* Password: **paste the token**

Example:

```sh
git clone https://github.com/USERNAME/repo1.git
```

Terminal will ask:

```
Username: yourgithubusername
Password: <paste token here>
```

---

### **Option 2: Use token in curl/xargs bulk clone script**

Example:

```sh
curl -H "Authorization: token YOUR_TOKEN" \
     -s "https://api.github.com/user/repos?per_page=200" \
| grep -o 'git@[^"]*' \
| xargs -L1 git clone
```

Replace:

```
YOUR_TOKEN
```

with the token you generated.

---

# ⭐ Tip: Store token in Git credential helper

To avoid typing it every time:

```sh
git config --global credential.helper store
```

Then once you enter your token, Git will remember it.

---
