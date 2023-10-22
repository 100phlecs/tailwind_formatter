const { createContext } = require("tailwindcss/lib/lib/setupContextUtils.js")
const resolveConfig = require("tailwindcss/resolveConfig.js")
const fs = require("fs")
const path = require("path")

async function loadCustomConfig(configPath) {
  let finalPath = path.isAbsolute(configPath)
    ? configPath
    : path.resolve(path.resolve(process.cwd(), configPath))

  if (!fs.existsSync(finalPath)) {
    const err = new Error("Config file does not exist")
    err.code = 2
    throw err
  }
  const tailwindConfig = require(finalPath)
  return tailwindConfig
}

async function extract(absoluteConfigPath) {
  const customConfig = await loadCustomConfig(absoluteConfigPath)
  const twConfig = await resolveConfig(customConfig)
  const twContext = await createContext(twConfig)

  let allVariants = [...twContext.variantMap.keys()].join("\n")
  let allClasses = twContext.getClassList().join("\n")

  fs.writeFileSync("_build/classes.txt", allClasses)
  fs.writeFileSync("_build/variants.txt", allVariants)
}

let localModules = {
  "tailwindcss/colors": require("tailwindcss/colors"),
  "tailwindcss/plugin": require("tailwindcss/plugin"),
  "tailwindcss/defaultConfig": require("tailwindcss/defaultConfig"),
  "tailwindcss/defaultTheme": require("tailwindcss/defaultTheme"),
  "tailwindcss/resolveConfig": require("tailwindcss/resolveConfig"),
  "@tailwindcss/aspect-ratio": require("@tailwindcss/aspect-ratio"),
  "@tailwindcss/forms": require("@tailwindcss/forms"),
  "@tailwindcss/typography": require("@tailwindcss/typography"),
}

let Module = require("module")
let origRequire = Module.prototype.require
Module.prototype.require = function (id) {
  if (localModules.hasOwnProperty(id)) {
    return localModules[id]
  }
  return origRequire.apply(this, arguments)
}

extract(process.argv[2])
