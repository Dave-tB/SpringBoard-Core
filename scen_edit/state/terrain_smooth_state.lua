TerrainSmoothState = AbstractHeightmapEditingState:extends{}

function TerrainSmoothState:GetCommand(x, z, strength)
    self.sigma = math.max(math.min(math.sqrt(math.sqrt(strength)) / 2, 1.5), 0.20)
    return TerrainSmoothCommand({
        x = x,
        z = z,
        size = self.size,
        shapeName = self.paintTexture,
        rotation = self.rotation,
        sigma = self.sigma,

        strength = strength,
    })
end

--gl.Color(0, 1, 0, 0.4)