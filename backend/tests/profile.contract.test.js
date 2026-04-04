jest.mock("../src/middleware/errorHandler", () => ({
  asyncHandler: (fn) => fn,
}));

jest.mock("../src/utils/ApiResponse", () => ({
  sendSuccess: jest.fn(),
}));

jest.mock("../src/services/CacheService", () => ({
  generateUserKey: jest.fn(() => "user:1:profile"),
  del: jest.fn().mockResolvedValue(undefined),
  get: jest.fn().mockResolvedValue(null),
  set: jest.fn().mockResolvedValue(undefined),
}));

const UserService = require("../src/services/UserService");
const router = require("../src/routes/user.routes");
const userController = require("../src/controllers/user.controller");
const { sendSuccess } = require("../src/utils/ApiResponse");

describe("Profile Contract - /api/v1/users/me", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("enforces route-level validation middleware on PUT /users/me", () => {
    const putMeLayer = router.stack.find(
      (layer) =>
        layer.route && layer.route.path === "/me" && layer.route.methods.put,
    );

    expect(putMeLayer).toBeDefined();
    expect(putMeLayer.route.stack).toHaveLength(2);
  });

  it("returns full updated profile payload from PUT /users/me (no ack-only response)", async () => {
    const updatedProfile = {
      name: "Updated Name",
      avatarUrl: "https://example.com/avatar.png",
    };

    jest
      .spyOn(UserService.prototype, "updateProfile")
      .mockResolvedValue(updatedProfile);
    jest
      .spyOn(UserService.prototype, "getUserProfile")
      .mockResolvedValue(updatedProfile);

    const req = {
      user: { _id: "user-1" },
      body: { name: "Updated Name" },
    };
    const res = {};
    const next = jest.fn();

    await userController.updateMe(req, res, next);

    expect(UserService.prototype.updateProfile).toHaveBeenCalledWith(
      "user-1",
      expect.objectContaining({ name: "Updated Name" }),
    );
    expect(UserService.prototype.getUserProfile).toHaveBeenCalledWith("user-1");
    expect(sendSuccess).toHaveBeenCalledWith(
      res,
      200,
      "Profile updated.",
      updatedProfile,
    );
    expect(next).not.toHaveBeenCalled();
  });
});
