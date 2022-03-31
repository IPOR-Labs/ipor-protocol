import chai from "chai";

const { expect } = chai;

// ########################################################################################################
//                                           assert
// ########################################################################################################

type ErrorWithMessage = {
    message: string;
};

const isErrorWithMessage = (error: unknown): error is ErrorWithMessage => {
    return (
        typeof error === "object" &&
        error !== null &&
        "message" in error &&
        typeof (error as Record<string, unknown>).message === "string"
    );
};

const toErrorWithMessage = (maybeError: unknown): ErrorWithMessage => {
    if (isErrorWithMessage(maybeError)) return maybeError;

    try {
        return new Error(JSON.stringify(maybeError));
    } catch {
        // fallback in case there's an error stringifying the maybeError
        // like with circular references for example.
        return new Error(String(maybeError));
    }
};

export const assertError = async (promise: Promise<any>, error: string) => {
    try {
        await promise;
    } catch (e: unknown) {
        const errorResult = toErrorWithMessage(e);
        expect(
            errorResult.message.includes(error),
            `Expected exception with message ${error} but actual error message: ${errorResult.message}`
        ).to.be.true;
        return;
    }
    expect(false).to.be.true;
};
