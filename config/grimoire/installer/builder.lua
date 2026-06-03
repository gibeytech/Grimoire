local Builder = {}

local Packaging = require("packaging")

function Builder.build(profile, options)
    return Packaging.setup.new(profile, options)
end

function Builder.build_from_request(request)
    return Packaging.setup.new(
        request.profile,
        {
            developer = request.developer,
            containers = request.containers,
            virtualization = request.virtualization,
        }
    )
end

return Builder
