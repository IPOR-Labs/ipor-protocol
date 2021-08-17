module.exports.assertError = async (promise, error) => {
    try {
        await promise;
    } catch (e) {
        assert(e.message.includes(error), `Expected exception with message ${error} but actu
        al error message: ${e.message}`)
        return;
    }
    assert(false);
}
