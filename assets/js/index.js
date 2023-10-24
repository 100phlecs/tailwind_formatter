const resolveConfig = require("tailwindcss/resolveConfig")
const { createContext } = require("/snapshot/tailwindcss/lib/lib/setupContextUtils.js")
const fs = require("fs")

const path = require("path")

async function extract(customConfig, buildPath) {
  const twConfig = await resolveConfig(customConfig)
  const twContext = await createContext(twConfig)

  let allVariants = [...twContext.variantMap.keys()].join("\n")
  let allClasses = twContext
    .getClassList({ includeMetadata: true })
    .flatMap((maybeClass) => {
      if (typeof maybeClass === "string") return maybeClass

      const [className, { modifiers }] = maybeClass
      return [className, ...modifiers.map((m) => `${className}/${m}`)]
    })
    .join("\n")

  fs.writeFileSync(path.resolve(buildPath, "classes.txt"), allClasses)
  fs.writeFileSync(path.resolve(buildPath, "variants.txt"), allVariants)
}

module.exports = {
  extract,
}
